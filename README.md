# FieldSales CRM

Web-first, mobile-responsive personal CRM for leads and follow-ups.

## Current implementation

- Dashboard metrics and lead pipeline
- Add leads with contact, business, phone, source, estimated value, notes and next follow-up
- Search and filter leads; change lead status
- Follow-up task list with completion toggles
- Starter demo records
- Responsive navigation and layout for desktop and mobile
- Supabase email/password authentication and owner-scoped cloud storage for leads, follow-ups, activities, projects and milestones
- Row Level Security on all CRM tables

## AI calling workspace\n\nAn initial AI calling workspace is available at `/ai-calling`. It includes per-user calling policy settings, human-assisted and AI voice-agent modes, call-script preparation, consent confirmation, and a Supabase-backed call preparation queue. The current release does not place calls, connect a telephony provider, generate scripts with an LLM, or enforce daily limits/cooldowns at a server execution boundary. Outbound execution is off by default. Apply `supabase/migrations/0003_ai_sales_calling.sql` before using this page.\n\n## Important limitations

This is an early CRM release, not production-ready. Cloud authentication and owner-scoped storage are implemented, but durable offline sync/conflict resolution, notifications, actual payment records and live telephony are not implemented. Demo records, if shown, are sample data.

## Run locally

Requires Node.js 20.9 or newer.

1. Run npm install
2. Run npm run dev
3. Open http://localhost:3000

Run npm run build to validate a production build.

## Vercel

Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or `NEXT_PUBLIC_SUPABASE_ANON_KEY`) in Vercel. Use the CRM project's URL and publishable/anon key only; never expose a service-role key in browser environment variables.

## Next steps

1. Install dependencies and run a production build; fix any errors.
2. Add durable offline sync/conflict resolution and notification delivery.
3. Implement a persistent offline queue and tested sync/conflict behavior.
4. Add project milestones, payment tracking and reminders.
5. Add a complete installable PWA and test on a real Android device.
6. Package an APK only after the web app and sync behavior have been validated.

Do not store sensitive customer data in this demo until authentication and cloud security are implemented. Never commit secrets or Supabase service-role keys.
