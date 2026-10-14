import { createClient } from '@/lib/supabase/server';
import { redirect } from 'next/navigation';
import { AppShell } from '@/components/app-shell';

export default async function Layout({ children }: { children: React.ReactNode }) {
  const supabase = await createClient();
  const { data } = await supabase.auth.getClaims();

  if (!data?.claims) {
    redirect('/auth/login');
  }

  const [{ data: entitlements }, { data: isPlatformOperator }] = await Promise.all([
    supabase.rpc('get_my_entitlements'),
    supabase.rpc('is_platform_operator'),
  ]);

  return <AppShell entitlements={entitlements ?? undefined} isPlatformOperator={Boolean(isPlatformOperator)}>{children}</AppShell>;
}
