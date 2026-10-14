# BiasharaOS

Kenya-first SME business operating system built with Next.js, React, Tailwind CSS and Supabase. The project includes a public marketing site, plan-aware workspace navigation, subscription centre and a restricted platform Watchtower foundation.

## Local setup

1. Install Node.js 20.9 or newer.
2. Copy `env.example` to `.env.local`.
3. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or the legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY`) in `.env.local`.
4. In the Supabase SQL Editor, run migrations in this exact order:
   - `supabase/migrations/001_initial.sql`
   - `supabase/migrations/002_workspace_onboarding.sql`
   - `supabase/migrations/003_subscriptions_watchtower.sql`
5. Install dependencies and run the development server:

   ```bash
   npm install
   npm run dev
   ```

6. Open `http://localhost:3000`. The roadmap and sitemap are available at `/roadmap`.
7. Run `npm run build` before deploying.

## Enable the Watchtower owner account

The Watchtower is not intended for every signed-in business user. After you have registered your own platform-owner account, run this in the Supabase SQL Editor, replacing the email with the exact email of your account:

```sql
insert into public.platform_operators (user_id, role)
select id, 'owner'
from auth.users
where lower(email) = lower('YOUR_PLATFORM_OWNER_EMAIL')
on conflict (user_id) do update set role = 'owner';
```

Only add trusted operators. The `/control-tower` and `/admin` routes check the platform-operator record server-side. Do not grant operator status from client-side signup metadata.

## Subscription behaviour

- Registration includes a Starter, Business or Pro plan selection.
- Migration 003 creates the plan catalogue and assigns new businesses a 14-day trial on the selected active plan.
- Existing organisations are backfilled onto Starter for a 14-day trial if they do not already have a subscription record.
- Workspace navigation and page access are filtered using subscription entitlements.
- The subscription centre and Watchtower are monitoring foundations. Automatic M-PESA/card collection, payment reconciliation, renewals, downgrade handling, and production-grade feature enforcement in every server action/database mutation still require implementation and tests before commercial launch.
- Demo pages still contain sample records. Do not interpret those as real customer or transaction data.

## Deploy to Vercel

Import the GitHub repository into Vercel. In **Project Settings → Environment Variables**, set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or the legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY`) for each deployment environment, then redeploy. Run all three migrations in the same Supabase project. In Supabase Authentication → URL Configuration, set the Site URL to your Vercel domain and add `https://YOUR-VERCEL-DOMAIN/auth/callback` to Redirect URLs.

Never commit `.env.local`, passwords, Supabase service-role keys, or other secrets to GitHub. The `.gitignore` excludes local environment files and build output.

## Project structure

- `app/(marketing)/` — public website and roadmap/sitemap
- `app/(app)/` — signed-in workspace, subscription centre and restricted Watchtower routes
- `app/auth/` — registration, login and auth callback
- `components/` — shared UI components
- `lib/` — Supabase clients, entitlement guard and shared types
- `supabase/migrations/` — database migrations
- `PRODUCT_BLUEPRINT.md` — product scope and design principles
- `PRODUCT_ROADMAP.md` — phased delivery plan and launch checklist
