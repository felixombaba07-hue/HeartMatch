import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';

type CoinPackage = { id: string; label: string; amountKes: number; coins: number };
function getPackages(): CoinPackage[] {
  try {
    const parsed = JSON.parse(process.env.HEARTMATCH_COIN_PACKAGES_JSON || '[]');
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((p: any) => p && typeof p.id === 'string' &&
      /^[a-z0-9_-]{1,40}$/i.test(p.id) && typeof p.label === 'string' &&
      p.label.length <= 60 && Number.isSafeInteger(p.amountKes) && p.amountKes > 0 &&
      Number.isSafeInteger(p.coins) && p.coins > 0);
  } catch { return []; }
}
function env(name: string, fallback?: string) {
  const value = process.env[name] || fallback;
  if (!value) throw new Error('Server configuration missing: ' + name);
  return value;
}

export default async function handler(req: any, res: any) {
  res.setHeader('Cache-Control', 'no-store');
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  try {
    const auth = String(req.headers.authorization || '');
    const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!token) return res.status(401).json({ error: 'Sign in before purchasing coins.' });
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const packageId = String(body?.packageId || '');
    const selected = getPackages().find(p => p.id === packageId);
    if (!selected) return res.status(400).json({ error: 'Choose a valid coin package.' });

    const supabaseUrl = env('VITE_SUPABASE_URL', process.env.SUPABASE_URL);
    const serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userResult, error: userError } = await admin.auth.getUser(token);
    if (userError || !userResult.user?.id || !userResult.user.email) {
      return res.status(401).json({ error: 'Your session is invalid. Sign in again.' });
    }
    const reference = 'HM_' + randomUUID().replace(/-/g, '');
    const { error: insertError } = await admin.from('coin_purchases').insert({
      user_id: userResult.user.id,
      reference,
      package_id: selected.id,
      amount_kes: selected.amountKes,
      coins: selected.coins,
      status: 'pending'
    });
    if (insertError) throw new Error('Could not create purchase record. Run the latest Supabase migration first.');

    const siteUrl = (process.env.HEARTMATCH_SITE_URL || (process.env.VERCEL_URL ? 'https://' + process.env.VERCEL_URL : '')).replace(/\/$/, '');
    if (!siteUrl) throw new Error('Set HEARTMATCH_SITE_URL to your deployed HeartMatch URL.');
    const response = await fetch('https://api.paystack.co/transaction/initialize', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + env('PAYSTACK_SECRET_KEY'), 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: userResult.user.email,
        amount: String(selected.amountKes * 100),
        currency: 'KES',
        reference,
        callback_url: siteUrl + '/?payment=success',
        metadata: { user_id: userResult.user.id, package_id: selected.id, coins: selected.coins }
      })
    });
    const result = await response.json();
    if (!response.ok || !result.status || !result.data?.authorization_url) {
      await admin.from('coin_purchases').update({ status: 'failed' }).eq('reference', reference);
      throw new Error(result.message || 'Paystack could not initialize checkout.');
    }
    return res.status(200).json({ authorization_url: result.data.authorization_url, reference });
  } catch (error: any) {
    return res.status(500).json({ error: error?.message || 'Could not start payment.' });
  }
}
