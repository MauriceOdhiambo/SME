'use client';
import { FormEvent, useState } from 'react';
import Link from 'next/link';
import { Logo } from '@/components/logo';
import { createClient } from '@/lib/supabase/client';

export default function SignUp() {
  const [form, setForm] = useState({ name: '', business: '', email: '', password: '' });
  const [msg, setMsg] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault(); setError(''); setMsg(''); setBusy(true);
    try {
      const supabase = createClient();
      const { data, error: signUpError } = await supabase.auth.signUp({
        email: form.email.trim(), password: form.password,
        options: { data: { full_name: form.name.trim(), business_name: form.business.trim() } },
      });
      if (signUpError) throw signUpError;
      if (data.session) {
        const { error: workspaceError } = await supabase.rpc('ensure_my_workspace');
        if (workspaceError) throw new Error(`Your account was created, but workspace setup failed. In Supabase SQL Editor, run supabase/migrations/002_workspace_onboarding.sql. Details: ${workspaceError.message}`);
        window.location.assign('/dashboard');
        return;
      }
      setMsg('If this email is eligible for registration, an account has been created. Check your inbox (and spam folder) for the confirmation link, then return here to sign in.');
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Unable to create your account. Please try again.';
      setError(message.includes('User already registered') ? 'An account with this email already exists. Please sign in instead or use password reset.' : message);
    } finally { setBusy(false); }
  }

  return <main className="min-h-screen bg-slate-50 px-5 py-10"><div className="mx-auto max-w-md"><Logo/><div className="card mt-10 p-7"><h1 className="text-2xl font-black">Create your workspace</h1><p className="mt-2 text-sm text-slate-500">Create your account and business workspace to get started.</p><form onSubmit={submit} className="mt-7 space-y-4">{([['name','Your name','text'],['business','Business name','text'],['email','Work email','email'],['password','Password (8+ characters)','password']] as const).map(([key,label,type])=><label key={key} className="block text-sm font-bold">{label}<input required minLength={key==='password'?8:1} type={type} autoComplete={key==='password'?'new-password':key==='email'?'email':'name'} value={form[key]} onChange={e=>setForm({...form,[key]:e.target.value})} className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 outline-none focus:border-teal-600"/></label>)}{error&&<div role="alert" className="rounded-xl bg-red-50 p-3 text-sm text-red-700">{error}</div>}{msg&&<div role="status" className="rounded-xl bg-teal-50 p-3 text-sm text-teal-800">{msg}</div>}<button disabled={busy} className="btn btn-primary w-full disabled:opacity-60">{busy?'Creating account…':'Create workspace'}</button></form><p className="mt-6 text-center text-sm text-slate-500">Already have access? <Link className="font-bold text-teal-700" href="/auth/login">Sign in</Link></p></div></div></main>;
}
