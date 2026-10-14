import { redirect } from 'next/navigation';
import { createClient } from '@/lib/supabase/server';

/** Server-side page guard. Database policies and server actions must also enforce entitlements for every data mutation. */
export async function requireFeature(feature: string) {
  const supabase = await createClient();
  const { data, error } = await supabase.rpc('get_my_entitlements');
  if (error) redirect('/subscription');
  const entitlements = data as { features?: Record<string, boolean>; access_limited?: boolean } | null;
  if (entitlements?.features?.[feature] === false || entitlements?.access_limited) redirect('/subscription');
}
