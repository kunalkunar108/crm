# FieldSales CRM

Web-first, mobile-responsive personal CRM for leads and follow-ups.

## Current implementation

- Dashboard metrics and lead pipeline
- Add leads with contact, business, phone, source, estimated value, notes and next follow-up
- Search and filter leads; change lead status
- Follow-up task list with completion toggles
- Starter demo records
- Responsive navigation and layout for desktop and mobile
- Browser localStorage persistence and basic offline-friendly access after the app has loaded

## Important limitations

This is an initial UI MVP, not a production-ready CRM. Data is stored only in the current browser on the current device. It will **not** sync between your PC and phone. Authentication, Supabase cloud storage, durable offline sync/conflict resolution, notifications, detailed project milestones and actual payment records have not been implemented yet. The Projects page is intentionally a placeholder. Demo records are sample data.

## Run locally

Requires Node.js 20.9 or newer.

1. Run npm install
2. Run npm run dev
3. Open http://localhost:3000

Run npm run build to validate a production build.

## Vercel

Import kunalkunar108/crm into Vercel as a Next.js project. No environment variables are needed for this local-storage preview.

## Next steps

1. Install dependencies and run a production build; fix any errors.
2. Add Supabase authentication, database tables and row-level security.
3. Implement a persistent offline queue and tested sync/conflict behavior.
4. Add project milestones, payment tracking and reminders.
5. Add a complete installable PWA and test on a real Android device.
6. Package an APK only after the web app and sync behavior have been validated.

Do not store sensitive customer data in this demo until authentication and cloud security are implemented. Never commit secrets or Supabase service-role keys.
