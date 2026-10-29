# HeartMatch
HeartMatch Vercel + Supabase migration scaffold.

## Setup
1. Copy `.env.example` to `.env.local` and set your Supabase Project URL and publishable key.
2. Run all three SQL files in `supabase/migrations/` in filename order in Supabase SQL Editor: `202610290001_heartmatch.sql`, `202610290002_security_hardening.sql`, then `202610290003_realtime_gallery.sql`.
3. In Supabase Storage, the migration creates/sets policies for the `profile-media` bucket.
4. Run `npm install`, `npm run build`, then deploy the GitHub repository to Vercel.
5. In Vercel project settings add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`.
6. Configure Supabase Auth Site URL and redirect URLs for localhost and your Vercel domain.

The publishable key is intended for browser use; database permissions must be enforced with RLS. Do not add database passwords, Supabase secret/service-role keys, or Paystack secret keys to the frontend or Git repository.

## Scope note
This migration establishes a new Supabase-backed foundation. Test auth, SQL policies, uploads, matching, chat and wallet flows in a non-production test account before switching over the existing AppDeploy app. Paystack server-side checkout/verification must be deployed separately as a protected Edge Function or server endpoint before real purchases are enabled.