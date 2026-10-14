# BiasharaOS product roadmap

## Product promise
A Kenya-first operating system for small and medium businesses: one workspace for daily operations, clear subscription tiers, and a private Watchtower for platform operations.

## Experience architecture

1. **Public website** — value proposition, use cases by industry, feature pages, transparent KES pricing, roadmap, contact/help, terms and privacy.
2. **Identity and onboarding** — sign-up, email verification, password reset, business details, industry template, plan selection, branch and team setup.
3. **Business workspace** — overview, POS, inventory, customers, invoices, team, reports, subscription, integrations and settings. Navigation is driven by plan entitlements.
4. **Watchtower Admin** — registered businesses, subscription state, trials/renewals, plan catalogue, payment reconciliation, support queue, operator permissions, audit events and system health. Operator access must be granted from trusted server/database administration, never client signup metadata.
5. **Platform services** — Supabase Auth, Postgres, RLS, entitlement functions, audit trails, notifications, observability, backups and payment/webhook services.

## Subscription model foundation

| Plan | Indicative price | Seats | Branches | Intended fit |
|---|---:|---:|---:|---|
| Starter | KES 1,000/month | 1 | 1 | Owner-operator; POS, stock and basic customer records |
| Business | KES 2,500/month | 5 | 1 | Small team; invoices and team workflows |
| Pro | KES 5,000/month | 15 | 5 | Growing operation; advanced reports and multi-branch readiness |

These are initial product assumptions, not validated market pricing. Test willingness to pay, support cost, payment fees and feature use with real SMEs before treating them as final prices.

New registrations choose a plan. Migration 003 assigns the chosen active plan and a 14-day trial, stores feature flags and limits, and backfills existing organisations onto Starter. The workspace reads entitlements server-side. For production, each data-changing server action, API and database policy must also enforce feature and usage limits. Hiding a navigation item alone is not sufficient.

## Market gaps worth validating first

- **Fragmented tools:** connect sales, inventory, invoices and customer follow-up so owners do not have to reconcile several spreadsheets.
- **Mobile-money visibility:** reliable payment references, matching, reversals, fees and settlement reconciliation for M-PESA and other channels.
- **Tax-ready workflows:** investigate KRA eTIMS requirements and support validated invoice mapping; do not claim compliance until integration and professional review are complete.
- **Stock and cash-flow decisions:** reorder warnings, margin by product, overdue receivables, stock ageing and daily cash-up.
- **Accessible onboarding:** simple language, guided setup, migration templates and practical help for low digital confidence.
- **Transparent subscriptions:** KES prices, visible limits, trial expiry notices, clear renewal/cancellation and no surprise feature lockout.
- **Local sector workflows:** configurable templates for dukas/retail, salons, food service, hardware, agrovets and service providers rather than forcing one generic workflow on everyone.
- **Trust:** tenant isolation, role controls, audit logs, data export, backup/recovery and clear privacy practices.

Prioritise through interviews and observation with business owners, bookkeepers and frontline staff. Do not assume every market gap is universal; segment by business type, size, region and payment workflow.

## Delivery phases

### Phase 1 — Foundation and trust
- Verify sign-up, email confirmation, login, recovery and workspace creation end-to-end.
- Ensure tenant isolation and RLS policies cover every exposed table.
- Create plan selection, trial creation, feature entitlements and Watchtower operator allowlist.
- Replace all demo metrics with real database-backed data or clearly labelled demo states.

### Phase 2 — Daily operations
- Persist product catalogue and inventory ledger.
- Persist customers, invoices, payments and receipts.
- Implement POS transactions as atomic database operations, including stock deduction and idempotency.
- Add returns, cash-up, expense capture, supplier records and activity audit.

### Phase 3 — Subscription lifecycle
- Add payment provider integration after commercial account setup and webhook design.
- Store immutable provider events, verify signatures, deduplicate callbacks and reconcile settlement.
- Send trial, renewal, payment-failure and cancellation notices.
- Implement audited plan changes, proration policy, grace periods, downgrades, cancellations and exports.
- Add a billing test suite before any account is automatically restricted.

### Phase 4 — Management intelligence
- Sales and margin by product, category and branch.
- Receivables ageing, cash-flow view, stock ageing and reorder recommendations.
- Exports and accountant-ready summaries with clear definitions and date ranges.

### Phase 5 — Kenya integrations
- M-PESA/Daraja with callback validation, idempotency, reversal handling and reconciliation.
- eTIMS integration after current KRA requirements and credentials are verified.
- SMS/WhatsApp with consent, templates, delivery status and usage limits.
- Banking statement imports and matching rules.

### Phase 6 — Scale
- Offline-friendly flows and conflict-safe sync.
- Multi-branch roles, public API, webhooks and partner ecosystem.
- Regionalisation, operational analytics, recovery exercises and capacity testing.

## Go-live checklist

- [ ] `npm run build` and lint pass in CI.
- [ ] Test signup with email confirmation both enabled and disabled.
- [ ] Test each plan's included and excluded features and user/branch limits.
- [ ] Verify a tenant cannot read or mutate another tenant's records.
- [ ] Verify non-operators cannot access Watchtower pages or platform data.
- [ ] Run database policy tests for read/write operations and every role.
- [ ] Replace sample UI records with live database records or label them as demo.
- [ ] Test payment callback signatures, duplicate events, timeouts, reversals and reconciliation before live collection.
- [ ] Establish privacy notice, data retention, support, backup and incident response processes.
- [ ] Review tax/accounting outputs with a qualified professional before filing automation.
