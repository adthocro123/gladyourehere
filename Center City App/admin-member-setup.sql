-- ============================================================
-- CENTER CITY GYM — Give the admin a real member record
-- so the admin can log their own workouts.
-- Run this in: Supabase Dashboard -> SQL Editor -> New Query
-- Safe to run more than once.
-- ============================================================

-- Creates (or updates) a members row for adthocro@gmail.com and
-- links it to the matching auth.users login by email.
INSERT INTO public.members (user_id, email, first_name, last_name, plan, plan_category)
SELECT u.id, 'adthocro@gmail.com', 'Adam', 'Cross', 'Staff', 'Other'
FROM auth.users u
WHERE u.email = 'adthocro@gmail.com'
ON CONFLICT (email) DO UPDATE
  SET user_id = EXCLUDED.user_id;

-- Verify: should return one row with a non-null user_id.
SELECT id, email, user_id, first_name, last_name
FROM public.members
WHERE email = 'adthocro@gmail.com';
