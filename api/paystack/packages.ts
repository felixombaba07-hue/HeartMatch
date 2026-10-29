type CoinPackage = { id: string; label: string; amountKes: number; coins: number };

function getPackages(): CoinPackage[] {
  try {
    const raw = process.env.HEARTMATCH_COIN_PACKAGES_JSON;
    if (!raw) return [];
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed.filter((p: any) =>
      p && typeof p.id === 'string' && /^[a-z0-9_-]{1,40}$/i.test(p.id) &&
      typeof p.label === 'string' && p.label.length <= 60 &&
      Number.isSafeInteger(p.amountKes) && p.amountKes > 0 && p.amountKes <= 10000000 &&
      Number.isSafeInteger(p.coins) && p.coins > 0
    ).map((p: any) => ({ id: p.id, label: p.label, amountKes: p.amountKes, coins: p.coins }));
  } catch {
    return [];
  }
}

export default function handler(req: any, res: any) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('Content-Type', 'application/json');
  if (req.method !== 'GET') {
    res.setHeader('Allow', 'GET');
    return res.status(405).json({ error: 'Method not allowed' });
  }
  return res.status(200).json({ packages: getPackages() });
}
