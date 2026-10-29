# HeartMatch

HeartMatch is a React + Vite frontend backed by Supabase Auth, Postgres, Storage, RLS, and Realtime. Signup is restricted to adults aged 18+ in both the UI and database trigger.

## Deploy to Vercel

1. Import `felixombaba07-hue/HeartMatch` into Vercel and set the framework preset to **Vite**.
2. Build command: `npm run build`; output directory: `dist`.
3. Add these Vercel **Production** environment variables:
   - `VITE_SUPABASE_URL` = your Supabase Project URL
   - `VITE_SUPABASE_PUBLISHABLE_KEY` = your Supabase publishable key (browser-safe)
   - `SUPABASE_SERVICE_ROLE_KEY` = the server-only Supabase service-role key
   - `PAYSTACK_SECRET_KEY` = the server-only Paystack secret key
   - `HEARTMATCH_SITE_URL` = the exact production URL, e.g. `https://heart-match-zeta.vercel.app`
   - `HEARTMATCH_COIN_PACKAGES_JSON` = JSON array of coin packages, with `id`, `label`, `amountKes`, and `coins` fields. Choose and review your own prices and coin quantities before enabling sales. Example shape only: `[{"id":"starter","label":"Starter","amountKes":100,"coins":1000}]`.
4. Redeploy after changing environment variables.
5. In Supabase → Authentication → URL Configuration, set the Site URL to the production Vercel URL and add that URL to Redirect URLs.

Never put a Supabase service-role key or Paystack secret key in a `VITE_*` variable or commit it to GitHub. The browser receives only the Supabase publishable key.

## Database setup

Run these SQL files in filename order in Supabase SQL Editor:

1. `supabase/migrations/202610290001_heartmatch.sql`
2. `supabase/migrations/202610290002_security_hardening.sql`
3. `supabase/migrations/202610290003_realtime_gallery.sql`
4. `supabase/migrations/202610290004_friend_request_retry.sql`
5. `supabase/migrations/202610290005_paystack_coin_purchases.sql`

The migrations create the profile/social/chat/wallet tables, 121-item virtual gift catalogue, storage bucket, RLS policies, adult-age guard, realtime subscriptions, friend-request retry policy, and an idempotent coin-purchase ledger. If migrations 1–3 are already applied to your Supabase project, run only migrations 4 and 5. Do not rerun older migrations blindly on a live database; review SQL Editor output and resolve errors.

## Signup email delivery

Supabase's built-in email sender has a very low rate limit. To send verification emails to real users:

1. Verify a domain with an SMTP provider such as Resend.
2. In Supabase Dashboard, open **Authentication → Emails → SMTP Settings** and enable custom SMTP.
3. For Resend, host is `smtp.resend.com`, port `465` (SSL) or `587` (STARTTLS), username `resend`, and password is your Resend API key.
4. Use a sender address on the verified domain (e.g. `noreply@yourdomain.com`) and sender name `HeartMatch`.
5. Test a signup using an email address you control. Do not turn off email confirmation as a production workaround.

## Paystack coin purchases

The wallet now has a package-driven checkout flow:

- The browser asks the server for configured packages.
- The server authenticates the Supabase session and initializes Paystack using the server-only secret.
- The return flow verifies the transaction directly with Paystack.
- A database function credits the wallet only once and only after server verification.

Coin packages are intentionally not hard-coded because prices and coin amounts must be chosen by the project owner. Until `HEARTMATCH_COIN_PACKAGES_JSON`, `PAYSTACK_SECRET_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and the latest database migration are configured, checkout will not work. Test with Paystack test keys first; switch to live keys only after end-to-end tests pass. Virtual coins are for in-app features and are not withdrawable cash.

## Local development

```bash
npm install
cp .env.example .env.local
npm run dev
```

Set the Supabase URL and publishable key in `.env.local`. Run `npm run build` before deploying.

## Final verification checklist

- GitHub Actions build passes.
- Vercel production environment variables are set and the latest commit is deployed.
- Supabase migrations 1–5 are applied without errors.
- Custom SMTP sends a verification email to an address outside the project team.
- Test adult account can register, sign in, edit a profile, upload images, match, chat, send/redeem virtual gifts, and view its own wallet.
- Paystack test payment is verified server-side and credits coins exactly once.
- No production Paystack secret or Supabase service-role key appears in browser code or Git history.

This repository is the Vercel/Supabase migration foundation; it does not automatically migrate existing users or data from the original AppDeploy backend. Validate against adult test accounts before switching over.
