import { createClient } from '@supabase/supabase-js';

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
    if (!token) return res.status(401).json({ error: 'Sign in to verify your purchase.' });
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    const reference = String(body?.reference || '');
    if (!/^HM_[a-f0-9]{32}$/i.test(reference)) return res.status(400).json({ error: 'Invalid payment reference.' });

    const supabaseUrl = env('VITE_SUPABASE_URL', process.env.SUPABASE_URL);
    const serviceKey = env('SUPABASE_SERVICE_ROLE_KEY');
    const admin = createClient(supabaseUrl, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: userResult, error: userError } = await admin.auth.getUser(token);
    if (userError || !userResult.user?.id) return res.status(401).json({ error: 'Your session is invalid. Sign in again.' });

    const { data: purchase, error: purchaseError } = await admin.from('coin_purchases')
      .select('reference,user_id,amount_kes,coins,status')
      .eq('reference', reference).eq('user_id', userResult.user.id).maybeSingle();
    if (purchaseError || !purchase) return res.status(404).json({ error: 'Purchase not found for this account.' });
    if (purchase.status === 'paid') return res.status(200).json({ verified: true, alreadyCredited: true });
    if (purchase.status !== 'pending') return res.status(400).json({ error: 'This purchase is not pending.' });

    const response = await fetch('https://api.paystack.co/transaction/verify/' + encodeURIComponent(reference), {
      headers: { Authorization: 'Bearer ' + env('PAYSTACK_SECRET_KEY') }
    });
    const result = await response.json();
    const transaction = result?.data;
    if (!response.ok || !result.status || transaction?.status !== 'success') {
      return res.status(400).json({ error: 'Paystack has not confirmed this payment yet.' });
    }
    if (transaction.reference !== reference ||
        Number(transaction.amount) !== Number(purchase.amount_kes) * 100 ||
        transaction.currency !== 'KES') {
      return res.status(400).json({ error: 'Payment details did not match this purchase.' });
    }

    const { data: credited, error: creditError } = await admin.rpc('complete_coin_purchase', { p_reference: reference });
    if (creditError) throw new Error('Payment verified but wallet credit failed. Contact HeartMatch support with reference ' + reference + '.');
    return res.status(200).json({ verified: true, alreadyCredited: credited === false, coins: Number(purchase.coins) });
  } catch (error: any) {
    return res.status(500).json({ error: error?.message || 'Could not verify payment.' });
  }
}
