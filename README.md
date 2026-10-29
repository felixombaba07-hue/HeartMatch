# HeartMatch

HeartMatch is a React + Vite frontend backed by Supabase Auth, Postgres, Storage, RLS, and Realtime. The app enforces an 18+ minimum age in the signup flow and database trigger.

## Deploy to Vercel

1. Import `felixombaba07-hue/HeartMatch` into Vercel and set the framework preset to **Vite**.
2. Use build command `npm run build` and output directory `dist`.
3. Add these Vercel **Production** environment variables:
   - `VITE_SUPABASE_URL` = your Supabase Project URL
   - `VITE_SUPABASE_PUBLISHABLE_KEY` = your Supabase publishable key (browser-safe key only)
4. Redeploy after changing environment variables.
5. In Supabase → Authentication → URL Configuration, set the Site URL to your production Vercel URL and add that URL to Redirect URLs. Add localhost URLs only for local development.

Never put a Supabase service-role key, database password, or Paystack secret key in a `VITE_*` variable or commit it to GitHub.

## Database setup

Run the SQL migrations in filename order in Supabase SQL Editor:

1. `supabase/migrations/202610290001_heartmatch.sql`
2. `supabase/migrations/202610290002_security_hardening.sql`
3. `supabase/migrations/202610290003_realtime_gallery.sql`
4. `supabase/migrations/202610290004_friend_request_retry.sql`

The first migration creates the profile/social/chat/wallet tables, the 121-item virtual gift catalogue, RLS policies, and the `profile-media` storage bucket. The second migration adds server-side matching and an 18+ database guard. The third enforces the 10-photo gallery limit and enables realtime subscriptions. The fourth fixes retrying a friend request under RLS. Do not re-run older migrations blindly on a live database; the SQL is mostly idempotent but review any reported errors.

## Signup email delivery

Supabase's built-in email sender has a very low rate limit. To send verification emails to real users:

1. Verify a domain with an SMTP provider such as Resend.
2. In Supabase Dashboard, open **Authentication → Emails → SMTP Settings** and enable custom SMTP.
3. For Resend, use host `smtp.resend.com`, port `465` (SSL) or `587` (STARTTLS), username `resend`, and your Resend API key as the SMTP password.
4. Set the sender email to an address on your verified domain (for example `noreply@yourdomain.com`) and sender name to `HeartMatch`.
5. Test a signup using an email address you control. Do not turn off email confirmation as a production workaround.

## Payments

Real Paystack coin purchases are **not enabled in this repository yet**. The wallet currently supports the seeded starter balance and virtual gifts; the UI explicitly warns that purchases are disabled. Before enabling purchases, implement a server-side Paystack initialize/verify flow, an idempotent database credit operation, and configure a server-only `PAYSTACK_SECRET_KEY`. Define the coin package prices and amounts before accepting payments. Never accept a coin amount supplied by the browser as authoritative.

## Local development

```bash
npm install
cp .env.example .env.local
npm run dev
```

Use the Supabase URL and publishable key in `.env.local`. Run `npm run build` before deploying.

## Important

This repository is the Vercel/Supabase migration foundation. Verify authentication, profile setup, image uploads, matching, realtime chat, gifts, and database policies with adult test accounts before switching away from the existing AppDeploy deployment. The current repository does not automatically migrate data from the original AppDeploy backend.
