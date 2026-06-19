-- ============================================================
-- CENTER CITY GYM — Admin Account Setup
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================


-- ── 1. Add Adam as admin in the staff table ───────────────────
INSERT INTO public.staff (email, name, role)
VALUES ('adthocro@gmail.com', 'Adam Cross', 'admin')
ON CONFLICT (email) DO UPDATE
  SET name = 'Adam Cross',
      role = 'admin';


-- ── 2. Allow staff to read ALL members (for member lookup) ────
DROP POLICY IF EXISTS "staff_read_all_members" ON public.members;
CREATE POLICY "staff_read_all_members"
  ON public.members FOR SELECT
  USING (
    email = auth.email()
    OR EXISTS (
      SELECT 1 FROM public.staff
      WHERE email = auth.email()
      AND role IN ('admin', 'staff')
    )
  );


-- ── 3. Allow staff to read ALL check-ins (for today's stats) ─
DROP POLICY IF EXISTS "staff_read_all_checkins" ON public.checkins;
CREATE POLICY "staff_read_all_checkins"
  ON public.checkins FOR SELECT
  USING (
    member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.staff
      WHERE email = auth.email()
      AND role IN ('admin', 'staff')
    )
  );


-- ── 4. Allow staff to insert check-ins for any member ─────────
DROP POLICY IF EXISTS "staff_insert_any_checkin" ON public.checkins;
CREATE POLICY "staff_insert_any_checkin"
  ON public.checkins FOR INSERT
  WITH CHECK (
    member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
    OR EXISTS (
      SELECT 1 FROM public.staff
      WHERE email = auth.email()
      AND role IN ('admin', 'staff')
    )
  );
