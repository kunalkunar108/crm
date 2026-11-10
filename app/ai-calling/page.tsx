"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { supabase } from "@/lib/supabase";

type Rules = {
  assistant_enabled: boolean;
  voice_agent_enabled: boolean;
  outbound_enabled: boolean;
  require_recorded_consent: boolean;
  allowed_start_hour: number;
  allowed_end_hour: number;
  max_calls_per_day: number;
  cooldown_hours: number;
};
type Lead = { id: string; name: string; business: string | null; phone: string | null; status: string; notes: string | null };
type QueueItem = { id: string; contact_name: string; phone: string; purpose: string; call_mode: string; status: string; created_at: string };

const defaults: Rules = {
  assistant_enabled: true,
  voice_agent_enabled: false,
  outbound_enabled: false,
  require_recorded_consent: true,
  allowed_start_hour: 10,
  allowed_end_hour: 18,
  max_calls_per_day: 20,
  cooldown_hours: 24,
};

function makeScript(lead: Lead, purpose: string) {
  const business = lead.business || "your business";
  const context = lead.notes?.trim() ? ` I have noted that ${lead.notes.trim()}.` : "";
  return `Hello ${lead.name}, this is Kunal from CURAKART Technologies. I'm reaching out regarding ${business}. ${purpose.trim() || "I wanted to understand whether you are currently considering help with your business growth or technology needs."}${context} Would this be a convenient time for a brief conversation? If not, I can call back at a time that suits you.\n\nIf they are not interested: Thank you for letting me know. I will update my records and won't follow up by phone.\nIf they ask not to be contacted: Apologise, confirm the request, and mark the contact as do-not-call immediately.\n\nDo not claim a prior relationship, guarantee results, or continue after a clear refusal.`;
}

export default function AICallingPage() {
  const [userId, setUserId] = useState<string | null>(null);
  const [authReady, setAuthReady] = useState(false);
  const [rules, setRules] = useState<Rules>(defaults);
  const [leads, setLeads] = useState<Lead[]>([]);
  const [queue, setQueue] = useState<QueueItem[]>([]);
  const [selectedLead, setSelectedLead] = useState("");
  const [purpose, setPurpose] = useState("I wanted to introduce our services and learn what would be most useful for your business.");
  const [mode, setMode] = useState<"human_assisted" | "ai_voice">("human_assisted");
  const [script, setScript] = useState("");
  const [consentConfirmed, setConsentConfirmed] = useState(false);
  const [busy, setBusy] = useState(false);
  const [notice, setNotice] = useState("");

  useEffect(() => {
    if (!supabase) { setAuthReady(true); return; }
    supabase.auth.getSession().then(async ({ data }) => {
      const id = data.session?.user.id ?? null;
      setUserId(id);
      if (id) {
        const [ruleResult, leadResult, queueResult] = await Promise.all([
          supabase!.from("ai_call_rules").select("*").eq("owner_id", id).maybeSingle(),
          supabase!.from("leads").select("id,name,business,phone,status,notes").not("phone", "is", null).order("created_at", { ascending: false }),
          supabase!.from("ai_call_queue").select("id,contact_name,phone,purpose,call_mode,status,created_at").order("created_at", { ascending: false }).limit(30),
        ]);
        if (ruleResult.data) setRules({ ...defaults, ...ruleResult.data });
        if (ruleResult.error) setNotice("Could not load calling rules: " + ruleResult.error.message);
        if (leadResult.data) setLeads(leadResult.data as Lead[]);
        if (leadResult.error) setNotice("Could not load leads: " + leadResult.error.message);
        if (queueResult.data) setQueue(queueResult.data as QueueItem[]);
        if (queueResult.error) setNotice("Could not load call queue: " + queueResult.error.message);
      }
      setAuthReady(true);
    }).catch(() => { setNotice("Could not check your sign-in session."); setAuthReady(true); });
  }, []);

  const selected = useMemo(() => leads.find((lead) => lead.id === selectedLead), [leads, selectedLead]);

  async function saveRules() {
    if (!supabase || !userId) return;
    setBusy(true);
    const { error } = await supabase.from("ai_call_rules").upsert({ ...rules, owner_id: userId, updated_at: new Date().toISOString() });
    setBusy(false);
    setNotice(error ? "Rules were not saved: " + error.message : "Calling rules saved. Outbound calling remains off until you enable it.");
  }

  function prepareScript() {
    if (!selected) { setNotice("Choose a lead first."); return; }
    setScript(makeScript(selected, purpose));
  }

  async function queueCall() {
    if (!supabase || !userId || !selected) return;
    const phone = selected.phone?.trim();
    if (!phone) { setNotice("This lead has no phone number."); return; }
    if (!consentConfirmed) { setNotice("Confirm that this contact has agreed to receive a sales call before adding it to the queue."); return; }
    if (mode === "ai_voice" && !rules.voice_agent_enabled) { setNotice("AI voice-agent mode is disabled in your rules."); return; }
    if (mode === "human_assisted" && !rules.assistant_enabled) { setNotice("Human-assisted calling is disabled in your rules."); return; }
    if (!script.trim()) { setNotice("Generate or write a call script first."); return; }

    setBusy(true);
    const { data, error } = await supabase.from("ai_call_queue").insert({
      owner_id: userId,
      lead_id: selected.id,
      contact_name: selected.name,
      phone,
      purpose,
      call_mode: mode,
      script,
      status: "queued",
      eligibility_snapshot: {
        consent_confirmed_by_user: consentConfirmed,
        outbound_enabled: rules.outbound_enabled,
        voice_agent_enabled: rules.voice_agent_enabled,
        note: "Queued for preparation only. No call is placed."
      }
    }).select("id,contact_name,phone,purpose,call_mode,status,created_at").single();
    setBusy(false);
    if (error) { setNotice("Could not queue call: " + error.message); return; }
    setQueue((items) => [data as QueueItem, ...items]);
    setNotice("Call added to the preparation queue. No phone call was placed.");
  }

  if (!authReady) return <main className="ai-page"><p>Loading your CRM session…</p></main>;
  if (!userId) return <main className="ai-page"><section className="ai-card"><h1>Sign in required</h1><p>Sign in to your CRM before managing calling rules.</p><Link href="/">Return to CRM</Link></section></main>;

  return (
    <main className="ai-page">
      <header className="ai-header">
        <div><p className="ai-kicker">AI SALES WORKSPACE</p><h1>Calling centre</h1><p className="ai-subtitle">Prepare sales calls, apply your calling rules, and review the queue.</p></div>
        <Link className="ai-back" href="/">← Back to CRM</Link>
      </header>
      {notice && <div className="ai-notice" role="status">{notice}<button onClick={() => setNotice("")}>×</button></div>}
      <section className="ai-warning"><b>Outbound calling is not connected.</b><span>This release prepares scripts and queues call jobs only. It does not dial numbers or use an AI voice provider.</span></section>
      <div className="ai-grid">
        <section className="ai-card">
          <div className="ai-card-title"><div><p className="ai-kicker">RULE ENGINE</p><h2>Calling permissions</h2></div><span className={rules.outbound_enabled ? "ai-pill ai-pill-warn" : "ai-pill"}>{rules.outbound_enabled ? "Outbound enabled" : "Outbound off"}</span></div>
          <label className="ai-toggle"><span><b>AI call assistant</b><small>Generate scripts and support calls you place yourself.</small></span><input type="checkbox" checked={rules.assistant_enabled} onChange={e => setRules(r => ({ ...r, assistant_enabled: e.target.checked }))}/></label>
          <label className="ai-toggle"><span><b>AI voice agent</b><small>Allow voice-agent jobs once a compliant provider is connected.</small></span><input type="checkbox" checked={rules.voice_agent_enabled} onChange={e => setRules(r => ({ ...r, voice_agent_enabled: e.target.checked }))}/></label>
          <label className="ai-toggle"><span><b>Enable outbound execution</b><small>Currently has no effect until a telephony integration is installed.</small></span><input type="checkbox" checked={rules.outbound_enabled} onChange={e => setRules(r => ({ ...r, outbound_enabled: e.target.checked }))}/></label>
          <label className="ai-toggle"><span><b>Require consent confirmation</b><small>Require you to confirm the contact agreed to a sales call.</small></span><input type="checkbox" checked={rules.require_recorded_consent} onChange={e => setRules(r => ({ ...r, require_recorded_consent: e.target.checked }))}/></label>
          <div className="ai-fields">
            <label>Allowed calling starts (local hour)<input type="number" min="0" max="23" value={rules.allowed_start_hour} onChange={e => setRules(r => ({ ...r, allowed_start_hour: Number(e.target.value) }))}/></label>
            <label>Allowed calling ends (local hour)<input type="number" min="1" max="24" value={rules.allowed_end_hour} onChange={e => setRules(r => ({ ...r, allowed_end_hour: Number(e.target.value) }))}/></label>
            <label>Maximum calls per day<input type="number" min="1" max="100" value={rules.max_calls_per_day} onChange={e => setRules(r => ({ ...r, max_calls_per_day: Number(e.target.value) }))}/></label>
            <label>Repeat-call cooldown (hours)<input type="number" min="1" max="720" value={rules.cooldown_hours} onChange={e => setRules(r => ({ ...r, cooldown_hours: Number(e.target.value) }))}/></label>
          </div>
          <button className="ai-primary" disabled={busy || rules.allowed_end_hour <= rules.allowed_start_hour} onClick={saveRules}>{busy ? "Saving…" : "Save calling rules"}</button>
        </section>
        <section className="ai-card">
          <p className="ai-kicker">CALL PREPARATION</p><h2>Prepare a sales call</h2>
          <label className="ai-field">Select a lead<select value={selectedLead} onChange={e => { setSelectedLead(e.target.value); setScript(""); }}><option value="">Choose a lead with a phone number</option>{leads.map(lead => <option key={lead.id} value={lead.id}>{lead.name} — {lead.business || "Business"}</option>)}</select></label>
          {selected && <div className="ai-contact"><b>{selected.name}</b><span>{selected.business} · {selected.phone}</span><small>Pipeline status: {selected.status}</small></div>}
          <label className="ai-field">Call objective<textarea rows={3} value={purpose} onChange={e => setPurpose(e.target.value)}/></label>
          <label className="ai-field">Calling mode<select value={mode} onChange={e => setMode(e.target.value as "human_assisted" | "ai_voice")}><option value="human_assisted">AI assistant + I make the call</option><option value="ai_voice">AI voice agent (provider not connected)</option></select></label>
          <button className="ai-secondary" onClick={prepareScript} disabled={!selected}>Generate call script</button>
          <label className="ai-field">Call script<textarea rows={9} value={script} onChange={e => setScript(e.target.value)} placeholder="Your prepared script will appear here. Edit it before queueing."/></label>
          <label className="ai-consent"><input type="checkbox" checked={consentConfirmed} onChange={e => setConsentConfirmed(e.target.checked)}/><span>I confirm this contact has agreed to receive a sales call and is not on a do-not-call list.</span></label>
          <button className="ai-primary" disabled={busy || !selected || !consentConfirmed || !script.trim()} onClick={queueCall}>{busy ? "Adding…" : "Add to call preparation queue"}</button>
          <p className="ai-footnote">This records a prepared task only. It never starts a call.</p>
        </section>
      </div>
      <section className="ai-card ai-queue">
        <div className="ai-card-title"><div><p className="ai-kicker">RECENT ACTIVITY</p><h2>Call preparation queue</h2></div><span className="ai-pill">{queue.length} recent</span></div>
        {queue.length === 0 ? <p className="ai-empty">No call tasks yet. Prepare a script and add the first task.</p> : <div className="ai-table-wrap"><table><thead><tr><th>CONTACT</th><th>PHONE</th><th>MODE</th><th>STATUS</th><th>ADDED</th></tr></thead><tbody>{queue.map(item => <tr key={item.id}><td>{item.contact_name}<small>{item.purpose}</small></td><td>{item.phone}</td><td>{item.call_mode === "ai_voice" ? "AI voice" : "Human-assisted"}</td><td><span className="ai-pill">{item.status}</span></td><td>{new Date(item.created_at).toLocaleString("en-IN", { dateStyle: "medium", timeStyle: "short" })}</td></tr>)}</tbody></table></div>}
      </section>
      <p className="ai-disclaimer">Rule-based execution is not yet active: daily caps, time windows, and cooldowns are stored as policy settings but must be enforced server-side before any provider can place calls. This page deliberately does not make outbound calls.</p>
    </main>
  );
}
