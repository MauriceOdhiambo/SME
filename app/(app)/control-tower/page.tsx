import Link from 'next/link';
import { redirect } from 'next/navigation';
import { Activity, AlertTriangle, Building2, CreditCard, ShieldCheck, Users, WalletCards, ArrowUpRight } from 'lucide-react';
import { createClient } from '@/lib/supabase/server';

const money = (value: number) => new Intl.NumberFormat('en-KE',{style:'currency',currency:'KES',maximumFractionDigits:0}).format(value);
const date = (value?: string | null) => value ? new Intl.DateTimeFormat('en-KE',{dateStyle:'medium'}).format(new Date(value)) : '—';

export default async function ControlTowerPage() {
  const supabase = await createClient();
  const { data: operator } = await supabase.rpc('is_platform_operator');
  if (!operator) redirect('/dashboard');

  const [orgs, memberships, subs, subscriptionRows, activeSubscriptionRows] = await Promise.all([
    supabase.from('organizations').select('id',{count:'exact',head:true}),
    supabase.from('memberships').select('id',{count:'exact',head:true}),
    supabase.from('subscriptions').select('id,status',{count:'exact'}),
    supabase.from('subscriptions').select('id,status,current_period_end,organization_id,organizations(name),subscription_plans(name,price_monthly_kes)').order('current_period_end',{ascending:true}).limit(8),
    supabase.from('subscriptions').select('id,subscription_plans(price_monthly_kes)').eq('status','active'),
  ]);
  const missingMigration = Boolean(subs.error || subscriptionRows.error);
  const rows = (subscriptionRows.data ?? []) as Array<{id:string;status:string;current_period_end:string;organization_id:string;organizations:{name:string}|{name:string}[]|null;subscription_plans:{name:string;price_monthly_kes:number}|{name:string;price_monthly_kes:number}[]|null}>;
  const relationName = (v: {name:string}|{name:string}[]|null) => Array.isArray(v) ? v[0]?.name ?? 'Business' : v?.name ?? 'Business';
  const relationPrice = (v: {price_monthly_kes:number}|{price_monthly_kes:number}[]|null) => Array.isArray(v) ? v[0]?.price_monthly_kes ?? 0 : v?.price_monthly_kes ?? 0;
  const statuses = subs.data ?? [];
  const needsAttention = statuses.filter(s => ['past_due','paused','expired'].includes(s.status)).length;
  const trialing = statuses.filter(s => s.status === 'trialing').length;
  const mrr = ((activeSubscriptionRows.data ?? []) as Array<{subscription_plans:{price_monthly_kes:number}|{price_monthly_kes:number}[]|null}>).reduce((sum,r)=>sum+relationPrice(r.subscription_plans),0);

  return <div className="space-y-7">
    <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><div><div className="text-xs font-bold uppercase tracking-[.16em] text-teal-700">Platform operations · Restricted</div><h1 className="mt-1 text-3xl font-black tracking-tight">Watchtower</h1><p className="mt-2 max-w-2xl text-sm leading-6 text-slate-500">Monitor tenant growth, subscription health, trial conversion and operational risk from one platform-level control centre.</p></div><Link className="btn btn-primary" href="/admin">Manage subscriptions <ArrowUpRight size={16} className="ml-2"/></Link></div>
    {missingMigration && <div role="alert" className="rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900"><b>Subscription monitoring needs setup.</b> Run <code>supabase/migrations/003_subscriptions_watchtower.sql</code> after migrations 001 and 002, then refresh this page.</div>}
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      {[
        {label:'Registered businesses',value:orgs.count ?? 0,detail:'Tenant workspaces',icon:Building2},
        {label:'Workspace memberships',value:memberships.count ?? 0,detail:'All active and invited memberships',icon:Users},
        {label:'Active subscriptions',value:statuses.filter(s=>s.status==='active').length,detail:`${trialing} trialing`,icon:CreditCard},
        {label:'Monthly recurring revenue',value:money(mrr),detail:'Active plans only · KES',icon:WalletCards},
      ].map(item=><div className="card p-5" key={item.label}><div className="flex items-center justify-between"><span className="text-sm font-semibold text-slate-500">{item.label}</span><span className="grid h-10 w-10 place-items-center rounded-xl bg-teal-50 text-teal-700"><item.icon size={19}/></span></div><div className="mt-5 text-3xl font-black tracking-tight">{item.value}</div><div className="mt-1 text-xs text-slate-400">{item.detail}</div></div>)}
    </div>
    <div className="grid gap-5 xl:grid-cols-[1.5fr_1fr]">
      <section className="card overflow-hidden"><div className="flex items-center justify-between border-b p-5"><div><h2 className="font-black">Subscription watchlist</h2><p className="mt-1 text-xs text-slate-500">Nearest renewals and trial expirations</p></div><Link href="/admin" className="text-sm font-bold text-teal-700">View all</Link></div>
        {rows.length ? <div className="overflow-x-auto"><table className="w-full min-w-[580px] text-left text-sm"><thead className="bg-slate-50 text-[11px] uppercase tracking-wider text-slate-500"><tr><th className="px-5 py-3">Business</th><th className="px-5 py-3">Plan</th><th className="px-5 py-3">Status</th><th className="px-5 py-3">Period ends</th></tr></thead><tbody className="divide-y">{rows.map(row=><tr key={row.id}><td className="px-5 py-4 font-bold">{relationName(row.organizations)}</td><td className="px-5 py-4">{relationName(row.subscription_plans)}<div className="text-xs text-slate-400">{money(relationPrice(row.subscription_plans))}/mo</div></td><td className="px-5 py-4"><span className={`rounded-full px-2.5 py-1 text-xs font-bold ${row.status==='active'?'bg-emerald-50 text-emerald-700':row.status==='trialing'?'bg-sky-50 text-sky-700':'bg-amber-50 text-amber-800'}`}>{row.status.replace('_',' ')}</span></td><td className="px-5 py-4 text-slate-500">{date(row.current_period_end)}</td></tr>)}</tbody></table></div> : <div className="p-8 text-center"><CreditCard className="mx-auto text-slate-300" size={28}/><p className="mt-3 font-bold">No subscription records yet</p><p className="mt-1 text-sm text-slate-500">New workspaces will appear here after migration 003 is installed.</p></div>}
      </section>
      <section className="card p-5"><div className="flex items-center gap-2"><ShieldCheck className="text-teal-700" size={20}/><h2 className="font-black">Platform health</h2></div><div className="mt-5 space-y-3">
        <div className="flex items-start gap-3 rounded-xl bg-slate-50 p-4"><Activity className="mt-0.5 text-teal-700" size={18}/><div><div className="text-sm font-bold">Tenant access controls</div><p className="mt-1 text-xs leading-5 text-slate-500">Platform operator access is checked server-side. Keep tenant data policies enabled.</p></div></div>
        <div className={`flex items-start gap-3 rounded-xl p-4 ${needsAttention?'bg-amber-50':'bg-emerald-50'}`}><AlertTriangle className={needsAttention?'mt-0.5 text-amber-700':'mt-0.5 text-emerald-700'} size={18}/><div><div className="text-sm font-bold">{needsAttention ? `${needsAttention} subscription(s) need attention` : 'No overdue states detected'}</div><p className="mt-1 text-xs leading-5 text-slate-500">Review past-due, paused or expired accounts before restricting access.</p></div></div>
        <div className="rounded-xl border p-4"><div className="text-sm font-bold">Integrations readiness</div><p className="mt-1 text-xs leading-5 text-slate-500">M-PESA, email/SMS, WhatsApp and eTIMS should remain labelled pending until credentials, callbacks, reconciliation and test cases are verified.</p></div>
      </div><Link href="/admin/plans" className="btn btn-secondary mt-4 w-full">Review plan entitlements</Link></section>
    </div>
  </div>;
}
