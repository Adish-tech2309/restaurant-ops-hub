-- =============================================================================
-- Restaurant Ops Hub — SaaS database schema (Supabase / Postgres)
-- Phase 1 foundation. Multi-tenant port of the single-file app's `roh-v1` model.
--
-- Conventions:
--   * Every tenant data table has restaurant_id (tenant key) + RLS enabled.
--   * ids are uuid, default gen_random_uuid().
--   * Money is NUMERIC (never float). Dates are DATE, times TIME, timestamps TIMESTAMPTZ.
--   * App field names that collide with SQL keywords are renamed with a documented
--     mapping (clock.in/out -> clock_in/clock_out). All other names map
--     snake_case <-> camelCase 1:1 (see docs/store-migration.md).
--   * RLS *policies* live in rls.sql; this file only ENABLEs RLS.
-- Run order: schema.sql, then rls.sql.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- updated_at auto-maintenance
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

-- =============================================================================
-- TENANCY CORE
-- =============================================================================

-- One row per restaurant (tenant). The old app's `settings`
-- (restaurantName / province / hstRate) now live on this row.
CREATE TABLE public.restaurants (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name        text NOT NULL,
  province    text NOT NULL DEFAULT 'Ontario',
  hst_rate    numeric(5,2) NOT NULL DEFAULT 13.00,
  sample_data_seeded boolean NOT NULL DEFAULT false,  -- per-tenant sample data flag
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

-- Profile row per auth user. id matches auth.users.id 1:1.
CREATE TABLE public.users (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email        text,
  display_name text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- Membership join: which users belong to which restaurant, and with what role.
-- Column is `member_role` (not `role`: ROLE is a reserved word in Postgres).
CREATE TABLE public.restaurant_members (
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  member_role   text NOT NULL CHECK (member_role IN ('owner','manager','staff')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (restaurant_id, user_id)
);

-- =============================================================================
-- STAFF  (app: DB.staff — name/role/phone/wage/hireDate/notes)
-- =============================================================================
CREATE TABLE public.staff (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  user_id       uuid REFERENCES public.users(id) ON DELETE SET NULL, -- optional link: lets a staff member log in
  name          text NOT NULL,
  role          text,                       -- job title, e.g. 'Server' (app field `role`)
  phone         text,
  wage          numeric(10,2),               -- hourly wage
  hire_date     date,
  notes         text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_staff_restaurant ON public.staff (restaurant_id);

-- =============================================================================
-- SHIFTS  (app: DB.shifts — staffId/date/start/end/role)
-- =============================================================================
CREATE TABLE public.shifts (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  staff_id      uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  date          date NOT NULL,
  start_time    time NOT NULL,               -- app `start` ("HH:MM")
  end_time      time NOT NULL,               -- app `end`   ("HH:MM")
  role          text,                        -- shift role label
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_shifts_restaurant_date ON public.shifts (restaurant_id, date);
CREATE INDEX idx_shifts_staff ON public.shifts (staff_id);

-- =============================================================================
-- CLOCK ENTRIES  (app: DB.clock — staffId/in/out; `out` null = on shift now)
-- NOTE: app fields `in`/`out` are SQL keywords -> clock_in / clock_out.
-- =============================================================================
CREATE TABLE public.clock_entries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  staff_id      uuid NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  clock_in      timestamptz NOT NULL,
  clock_out     timestamptz,                -- NULL = currently clocked in
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT clock_out_after_in CHECK (clock_out IS NULL OR clock_out >= clock_in)
);
CREATE INDEX idx_clock_restaurant_staff ON public.clock_entries (restaurant_id, staff_id, clock_in);

-- =============================================================================
-- PAY RUNS  (app: DB.payRuns — saved payroll estimates; staffName/wage are
-- point-in-time snapshots, kept even if the staff row is later deleted)
-- =============================================================================
CREATE TABLE public.pay_runs (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id     uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  staff_id          uuid REFERENCES public.staff(id) ON DELETE SET NULL,
  staff_name        text NOT NULL,          -- snapshot at save time
  wage              numeric(10,2),          -- snapshot at save time
  period_type       text NOT NULL CHECK (period_type IN ('weekly','biweekly','monthly')),
  period_start      date NOT NULL,
  period_end        date NOT NULL,
  hours             numeric(10,2) NOT NULL,
  gross             numeric(12,2) NOT NULL,
  cpp               numeric(12,2) NOT NULL DEFAULT 0,
  ei                numeric(12,2) NOT NULL DEFAULT 0,
  fed_tax           numeric(12,2) NOT NULL DEFAULT 0,
  on_tax            numeric(12,2) NOT NULL DEFAULT 0,
  total_deductions  numeric(12,2) NOT NULL DEFAULT 0,  -- app `total`
  net               numeric(12,2) NOT NULL,
  tips              numeric(12,2) NOT NULL DEFAULT 0,
  saved_at          timestamptz NOT NULL DEFAULT now(),
  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_payruns_restaurant ON public.pay_runs (restaurant_id, period_start);

-- =============================================================================
-- SALES DAYS  (app: DB.sales — date/dinein/takeout/delivery/catering)
-- `source` + `external_id` support POS imports with idempotent upserts:
-- one row per (restaurant, date, source).
-- =============================================================================
CREATE TABLE public.sales_days (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  date          date NOT NULL,
  dine_in       numeric(12,2) NOT NULL DEFAULT 0,  -- app `dinein`
  takeout       numeric(12,2) NOT NULL DEFAULT 0,
  delivery      numeric(12,2) NOT NULL DEFAULT 0,
  catering      numeric(12,2) NOT NULL DEFAULT 0,
  source        text NOT NULL DEFAULT 'manual'
                CHECK (source IN ('manual','square','lightspeed','toast','touchbistro')),
  external_id   text,                              -- provider-side id for dedup
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (restaurant_id, date, source)
);
CREATE INDEX idx_sales_restaurant_date ON public.sales_days (restaurant_id, date);

-- =============================================================================
-- INVOICES + ITEMS  (app: DB.invoices — client/dueDate/paid/createdAt/items[])
-- =============================================================================
CREATE TABLE public.invoices (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  client        text NOT NULL,
  due_date      date,
  paid          boolean NOT NULL DEFAULT false,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_invoices_restaurant ON public.invoices (restaurant_id, due_date);

CREATE TABLE public.invoice_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  invoice_id    uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  description   text NOT NULL,             -- app `desc`
  amount        numeric(12,2) NOT NULL,
  position      integer NOT NULL DEFAULT 0, -- line order
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_invoice_items_invoice ON public.invoice_items (invoice_id);

-- =============================================================================
-- EXPENSES  (app: DB.expenses — date/category/amount/hst/note/receipt)
-- `receipt` holds a data URL in v1. Move to Supabase Storage (bucket:
-- `receipts/<restaurant_id>/<expense_id>.jpg`) when rows grow — see note below.
-- =============================================================================
CREATE TABLE public.expenses (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  date          date NOT NULL,
  category      text NOT NULL
                CHECK (category IN ('Food','Labour','Rent','Utilities','Supplies','Other')),
  amount        numeric(12,2) NOT NULL,
  hst           numeric(12,2) NOT NULL DEFAULT 0,
  note          text,
  receipt       text,                       -- v1: data URL. Future: storage path.
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_expenses_restaurant_date ON public.expenses (restaurant_id, date);

-- =============================================================================
-- SUPPLIER BILLS  (app: DB.bills — supplier/amount/dueDate/paid/note)
-- =============================================================================
CREATE TABLE public.supplier_bills (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  supplier      text NOT NULL,
  amount        numeric(12,2) NOT NULL,
  due_date      date,
  paid          boolean NOT NULL DEFAULT false,
  note          text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_bills_restaurant ON public.supplier_bills (restaurant_id, due_date);

-- =============================================================================
-- CHECKLISTS + ITEMS  (app: DB.checklists — name/daily/items[{id,text,doneDate}])
-- =============================================================================
CREATE TABLE public.checklists (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  name          text NOT NULL,
  daily         boolean NOT NULL DEFAULT false,  -- auto-reset each day
  position      integer NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE public.checklist_items (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  checklist_id  uuid NOT NULL REFERENCES public.checklists(id) ON DELETE CASCADE,
  text          text NOT NULL,
  done_date     date,                            -- NULL = open
  position      integer NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_checklist_items_checklist ON public.checklist_items (checklist_id);

-- =============================================================================
-- POS CONNECTIONS  (one row per restaurant per POS provider)
-- Tokens are stored ENCRYPTED (envelope encryption via Supabase Vault / Edge
-- Function secret) inside `tokens` JSONB. Never log token values.
-- Shape of tokens (after decrypt): { access_token, refresh_token,
--   access_expires_at, merchant_id, location_ids[] } — provider-specific keys
--   allowed inside, but these five are the contract (see docs/connector-interface.md).
-- =============================================================================
CREATE TABLE public.pos_connections (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  provider      text NOT NULL
                CHECK (provider IN ('square','lightspeed','toast','touchbistro')),
  status        text NOT NULL DEFAULT 'active'
                CHECK (status IN ('active','expired','revoked','error')),
  tokens        jsonb NOT NULL DEFAULT '{}',     -- ENCRYPTED blob
  merchant_id   text,                            -- provider's merchant/location id (plaintext, for display)
  last_sync_at  timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  UNIQUE (restaurant_id, provider)
);

-- =============================================================================
-- SYNC LOGS  (audit trail for every connector run)
-- =============================================================================
CREATE TABLE public.sync_logs (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  restaurant_id    uuid NOT NULL REFERENCES public.restaurants(id) ON DELETE CASCADE,
  pos_connection_id uuid REFERENCES public.pos_connections(id) ON DELETE SET NULL,
  operation        text NOT NULL,             -- e.g. 'pullSales', 'pullStaff', 'pushSchedule', 'webhook'
  status           text NOT NULL DEFAULT 'started'
                   CHECK (status IN ('started','success','partial','failed')),
  started_at       timestamptz NOT NULL DEFAULT now(),
  finished_at      timestamptz,
  records_in       integer NOT NULL DEFAULT 0,
  records_out      integer NOT NULL DEFAULT 0,
  error            text,
  details          jsonb NOT NULL DEFAULT '{}',
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_synclogs_restaurant ON public.sync_logs (restaurant_id, started_at DESC);

-- =============================================================================
-- updated_at triggers
-- =============================================================================
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'restaurants','users','staff','shifts','clock_entries','pay_runs',
    'sales_days','invoices','invoice_items','expenses','supplier_bills',
    'checklists','checklist_items','pos_connections','sync_logs'
  ] LOOP
    EXECUTE format(
      'CREATE TRIGGER trg_%I_touch BEFORE UPDATE ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at()', t, t);
  END LOOP;
END $$;

-- =============================================================================
-- Enable RLS on every table (policies are defined in rls.sql)
-- =============================================================================
ALTER TABLE public.restaurants        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restaurant_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clock_entries      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pay_runs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_days         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_items      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.supplier_bills     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklists         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pos_connections    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sync_logs          ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- FUTURE MOVES (noted, not implemented in v1)
-- 1. expenses.receipt (data URL) -> Supabase Storage bucket `receipts`,
--    store the storage path in a new `receipt_path` column. Data URLs bloat
--    rows and break the 8KB tuple comfort zone; migrate once any restaurant
--    has > ~50 receipts.
-- 2. Partition sync_logs by month if a restaurant syncs aggressively.
-- 3. Consider a `subscription` / `billing` schema in Phase 4 (Stripe).
-- =============================================================================
