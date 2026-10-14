# BiasharaOS

Kenya-first SME business operating system built with Next.js, React, Tailwind CSS and Supabase.

## Local setup

1. Install Node.js 20.9 or newer.
2. Copy `env.example` to `.env.local`.
3. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or the legacy `NEXT_PUBLIC_SUPABASE_ANON_KEY`) in `.env.local`.
4. In the Supabase SQL Editor, run `supabase/migrations/001_initial.sql`, then run `supabase/migrations/002_workspace_onboarding.sql`.
5. Install dependencies and run the development server:

   ```bash
   npm install
   npm run dev
   ```

6. Open `http://localhost:3000`.
7. Check the production build before deploying:

   ```bash
   npm run build
   ```

## Deploy to Vercel

Import the GitHub repository into Vercel. In **Project Settings → Environment Variables**, set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` (or `NEXT_PUBLIC_SUPABASE_ANON_KEY`) for the environments you deploy, then redeploy. Ensure both SQL migrations have been run in the same Supabase project. In Supabase Authentication → URL Configuration, set the Site URL to your Vercel domain and add `https://YOUR-VERCEL-DOMAIN/auth/callback` to Redirect URLs.

Never commit `.env.local`, passwords, Supabase service-role keys, or other secrets to GitHub. The `.gitignore` excludes local environment files and build output.

## Project structure

- `app/` — App Router pages, layouts and auth callback route
- `components/` — shared UI components
- `lib/` — Supabase clients and shared types
- `supabase/migrations/` — database migration

Duplicate loose page/layout/route files from earlier copies have been removed. The canonical route files are inside `app/` and shared modules are inside `components/` and `lib/`.
