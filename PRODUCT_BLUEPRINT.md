# BiasharaOS Product Blueprint

## Product promise
A Kenya-first operating system for SMEs: one place to run daily operations, understand performance and progressively connect payments, tax and communications.

## Roles
- Owner: organisation ownership, commercial settings, all business controls.
- Admin: operational administration and user management.
- Manager: products, customers, invoices, reports and team workflows.
- Staff: permitted day-to-day operations such as POS.
- Member: restricted customer/member portal.
- Platform operator: control tower and tenant support; separate from an SME's own roles.

## Core domain model
Organisation → Branches → Users/Memberships → Products/Inventory → Customers → Sales/Invoices → Payments → Reports → Audit logs.

The database should remain the source of truth. The UI is a presentation layer and must never be the only place a permission is enforced.

## Professional gaps addressed in the foundation
- Multi-tenant isolation and RLS
- Role-based access foundation
- Separate platform operator and business administration surfaces
- Audit log foundation
- Integration readiness states
- Mobile-responsive application shell
- Clear information hierarchy and operational dashboard
- Business profile and branch-ready structure
- Commercial pricing and onboarding story

## Deliberately staged integrations
1. M-PESA / Daraja: credentials, callback URLs, webhook signature/verification, idempotency, reconciliation and reversal handling.
2. Banking: provider selection, account verification, statement ingestion and reconciliation rules.
3. Card payments: PSP contract, checkout/webhook flow, settlement reconciliation and refunds.
4. SMS: provider, sender ID, consent, delivery reporting and usage controls.
5. WhatsApp: Meta business verification, templates, opt-in and message state tracking.
6. eTIMS: KRA onboarding, invoice mapping, tax configuration, API credentials and failure/retry workflow.

## Before production
- Legal entity, terms, privacy notice and data-retention policy.
- Data protection review and access/retention procedures.
- Backup and disaster-recovery plan.
- Error monitoring, uptime monitoring and structured application logs.
- Automated unit/integration/end-to-end tests.
- Rate limiting and abuse protection.
- Secure secret management and separate development/staging/production projects.
- Payment reconciliation test suite before real money flows.
- Accounting/tax rules reviewed by a qualified professional before filing automation.

## Product roadmap
### Phase 1 — Foundation
Auth, organisations, branches, permissions, audit logs, dashboard, products, customers, invoices.

### Phase 2 — Daily operations
Real POS transactions, inventory ledger, returns, expenses, supplier records, cash-up and end-of-day close.

### Phase 3 — Business intelligence
Gross margin by product, branch profitability, receivables ageing, stock ageing, cash-flow view and management exports.

### Phase 4 — Integrations
Payments, banking, SMS, WhatsApp and eTIMS, each with reconciliation and failure handling.

### Phase 5 — Scale
Offline sync, multi-branch controls, API, partner ecosystem and regionalisation.

### Phase 6 — Financial products
Only after sufficient data quality, legal/compliance review and partnerships: financing referrals, not direct lending by default.
