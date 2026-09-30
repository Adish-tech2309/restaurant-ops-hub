-- =============================================================================
-- Restaurant Ops Hub — Row Level Security policies (Supabase / Postgres)
-- Run AFTER schema.sql. All helper functions are SECURITY DEFINER so policy
-- checks against `restaurant_members` never recurse into RLS themselves.
--
-- Access model:
--   owner / manager : full read+write on their restaurant's data
--   staff           : read-only on everything, EXCEPT they may insert/update
--                     their OWN clock entries (clock in/out from their phone)
--   pos_connections / sync_logs : owner/manager only (tokens are sensitive)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_member(rid uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.restaurant_members m
    WHERE m.restaurant_id = rid
      AND m.user_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.has_role(rid uuid, roles text[])
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.restaurant_members m
    WHERE m.restaurant_id = rid
      AND m.user_id = auth.uid()
      AND m.member_role = ANY (roles)
  );
$$;

-- The staff row (if any) linked to the calling user inside a restaurant.
-- Used so staff can clock themselves in/out but not touch anyone else's time.
CREATE OR REPLACE FUNCTION public.my_staff_id(rid uuid)
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT s.id FROM public.staff s
  WHERE s.restaurant_id = rid
    AND s.user_id = auth.uid()
  LIMIT 1;
$$;

-- =============================================================================
-- restaurants
-- =============================================================================
CREATE POLICY restaurants_select ON public.restaurants
  FOR SELECT USING (public.is_member(id));

CREATE POLICY restaurants_insert ON public.restaurants
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
-- NOTE: an AFTER INSERT trigger (below) makes the creator the owner.

CREATE POLICY restaurants_update ON public.restaurants
  FOR UPDATE USING (public.has_role(id, '{owner}'))
  WITH CHECK (public.has_role(id, '{owner}'));

CREATE POLICY restaurants_delete ON public.restaurants
  FOR DELETE USING (public.has_role(id, '{owner}'));

-- =============================================================================
-- users
-- =============================================================================
-- A user always sees their own profile; members of the same restaurant can see
-- each other (needed for the staff directory / schedule views).
CREATE POLICY users_select ON public.users
  FOR SELECT USING (
    id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.restaurant_members m1
      JOIN public.restaurant_members m2
        ON m1.restaurant_id = m2.restaurant_id
      WHERE m1.user_id = auth.uid()
        AND m2.user_id = public.users.id
    )
  );

CREATE POLICY users_insert ON public.users
  FOR INSERT WITH CHECK (id = auth.uid());

CREATE POLICY users_update ON public.users
  FOR UPDATE USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- =============================================================================
-- restaurant_members
-- =============================================================================
CREATE POLICY members_select ON public.restaurant_members
  FOR SELECT USING (public.is_member(restaurant_id));

CREATE POLICY members_insert ON public.restaurant_members
  FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));

CREATE POLICY members_update ON public.restaurant_members
  FOR UPDATE USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));

-- Only owners remove people. "Don't remove the last owner" is enforced in the
-- app/Edge Function layer (a COUNT check before delete), not here.
CREATE POLICY members_delete ON public.restaurant_members
  FOR DELETE USING (public.has_role(restaurant_id, '{owner}'));

-- =============================================================================
-- Standard tenant tables: staff, shifts, pay_runs, sales_days, invoices,
-- invoice_items, expenses, supplier_bills, checklists, checklist_items
-- Rule: members read; owner/manager write.
-- =============================================================================

-- staff
CREATE POLICY staff_select ON public.staff FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY staff_insert ON public.staff FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY staff_update ON public.staff FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY staff_delete ON public.staff FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- shifts
CREATE POLICY shifts_select ON public.shifts FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY shifts_insert ON public.shifts FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY shifts_update ON public.shifts FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY shifts_delete ON public.shifts FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- pay_runs (payroll figures are sensitive: owner/manager only, no staff access)
CREATE POLICY payruns_select ON public.pay_runs FOR SELECT USING (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY payruns_insert ON public.pay_runs FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY payruns_update ON public.pay_runs FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY payruns_delete ON public.pay_runs FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- sales_days
CREATE POLICY sales_select ON public.sales_days FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY sales_insert ON public.sales_days FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY sales_update ON public.sales_days FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY sales_delete ON public.sales_days FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- invoices
CREATE POLICY invoices_select ON public.invoices FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY invoices_insert ON public.invoices FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY invoices_update ON public.invoices FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY invoices_delete ON public.invoices FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- invoice_items
CREATE POLICY invitems_select ON public.invoice_items FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY invitems_insert ON public.invoice_items FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY invitems_update ON public.invoice_items FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY invitems_delete ON public.invoice_items FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- expenses
CREATE POLICY expenses_select ON public.expenses FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY expenses_insert ON public.expenses FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY expenses_update ON public.expenses FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY expenses_delete ON public.expenses FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- supplier_bills
CREATE POLICY bills_select ON public.supplier_bills FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY bills_insert ON public.supplier_bills FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY bills_update ON public.supplier_bills FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY bills_delete ON public.supplier_bills FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- checklists
CREATE POLICY checklists_select ON public.checklists FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY checklists_insert ON public.checklists FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY checklists_update ON public.checklists FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY checklists_delete ON public.checklists FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- checklist_items (staff tick boxes on their phone -> staff may UPDATE done_date)
CREATE POLICY chkitems_select ON public.checklist_items FOR SELECT USING (public.is_member(restaurant_id));
CREATE POLICY chkitems_insert ON public.checklist_items FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY chkitems_update ON public.checklist_items FOR UPDATE
  USING (public.is_member(restaurant_id))
  WITH CHECK (public.is_member(restaurant_id));
CREATE POLICY chkitems_delete ON public.checklist_items FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- =============================================================================
-- clock_entries — the one table with a staff self-service carve-out
-- =============================================================================
CREATE POLICY clock_select ON public.clock_entries
  FOR SELECT USING (public.is_member(restaurant_id));

-- Owner/manager can log time for anyone; a staff member can only clock
-- THEMSELVES in/out (their staff row must be linked to their user account).
CREATE POLICY clock_insert ON public.clock_entries
  FOR INSERT WITH CHECK (
    public.has_role(restaurant_id, '{owner,manager}')
    OR (
      public.is_member(restaurant_id)
      AND staff_id = public.my_staff_id(restaurant_id)
    )
  );

CREATE POLICY clock_update ON public.clock_entries
  FOR UPDATE
  USING (
    public.has_role(restaurant_id, '{owner,manager}')
    OR (
      public.is_member(restaurant_id)
      AND staff_id = public.my_staff_id(restaurant_id)
    )
  )
  WITH CHECK (
    public.has_role(restaurant_id, '{owner,manager}')
    OR (
      public.is_member(restaurant_id)
      AND staff_id = public.my_staff_id(restaurant_id)
    )
  );

CREATE POLICY clock_delete ON public.clock_entries
  FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- =============================================================================
-- pos_connections + sync_logs — owner/manager only (OAuth tokens live here)
-- =============================================================================
CREATE POLICY posconn_select ON public.pos_connections FOR SELECT USING (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY posconn_insert ON public.pos_connections FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY posconn_update ON public.pos_connections FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY posconn_delete ON public.pos_connections FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

CREATE POLICY synclog_select ON public.sync_logs FOR SELECT USING (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY synclog_insert ON public.sync_logs FOR INSERT WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY synclog_update ON public.sync_logs FOR UPDATE
  USING (public.has_role(restaurant_id, '{owner,manager}'))
  WITH CHECK (public.has_role(restaurant_id, '{owner,manager}'));
CREATE POLICY synclog_delete ON public.sync_logs FOR DELETE USING (public.has_role(restaurant_id, '{owner,manager}'));

-- =============================================================================
-- Bootstrap triggers (SECURITY DEFINER — bypass RLS by design)
-- =============================================================================

-- 1. Mirror every new auth.users row into public.users.
--    Run this in the Supabase SQL editor (postgres role) — it touches auth.users.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'display_name', split_part(NEW.email,'@',1))
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 2. Whoever creates a restaurant becomes its owner.
CREATE OR REPLACE FUNCTION public.handle_new_restaurant()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.restaurant_members (restaurant_id, user_id, member_role)
  VALUES (NEW.id, auth.uid(), 'owner')
  ON CONFLICT (restaurant_id, user_id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_restaurant_created ON public.restaurants;
CREATE TRIGGER on_restaurant_created
  AFTER INSERT ON public.restaurants
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_restaurant();

-- =============================================================================
-- SELF-REVIEW NOTES (kept with the policies so future edits stay consistent)
-- 1. No policy queries `restaurant_members` with the caller's privileges — all
--    membership checks go through the SECURITY DEFINER helpers, so there is no
--    RLS recursion. The one inline join (users_select) reads restaurant_members
--    through its own SELECT policy, which itself only calls the helper: safe.
-- 2. `staff` role can UPDATE checklist_items (tick boxes) and their own
--    clock_entries, and read everything except pay_runs / pos_connections /
--    sync_logs. This matches "staff see the ops board, not the money."
-- 3. INSERT policies use WITH CHECK (USING is ignored for INSERT in Postgres).
-- 4. DELETE of a restaurant cascades to all tenant tables (FK ON DELETE CASCADE).
-- 5. service_role / Edge Functions bypass RLS entirely — connectors use the
--    service key and MUST re-check membership in code (see connector-interface.md).
-- 6. Not enforced in SQL: "at least one owner must remain" and "a staff user
--    can only ever see their own pay" — both live in the app/Edge Function layer.
-- =============================================================================
