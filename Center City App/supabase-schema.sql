-- ============================================================
-- CENTER CITY GYM — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================


-- ── MEMBERS ──────────────────────────────────────────────────
-- Populated by importing members-import.csv after running this schema.
-- user_id links to Supabase Auth once a member creates their account.

CREATE TABLE public.members (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id          UUID        REFERENCES auth.users(id) ON DELETE SET NULL,
  email            TEXT        UNIQUE,
  first_name       TEXT        NOT NULL,
  last_name        TEXT        NOT NULL,
  phone            TEXT,
  barcode_id       TEXT        UNIQUE,
  plan             TEXT,
  plan_category    TEXT        CHECK (plan_category IN ('Monthly','3 Month','6 Month','Annual','Social District','Other')),
  contract_end     DATE,
  monthly_due      NUMERIC(8,2),
  payment_method   TEXT,
  status           TEXT        DEFAULT 'OK',
  total_revenue    NUMERIC(10,2),
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- Index for fast email lookups (used on login)
CREATE INDEX members_email_idx   ON public.members (email);
CREATE INDEX members_barcode_idx ON public.members (barcode_id);
CREATE INDEX members_user_id_idx ON public.members (user_id);


-- ── CHECK-INS ────────────────────────────────────────────────

CREATE TABLE public.checkins (
  id             UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id      UUID        NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  checked_in_at  TIMESTAMPTZ DEFAULT NOW(),
  method         TEXT        DEFAULT 'app'   -- 'app', 'qr_scan', 'manual'
);

CREATE INDEX checkins_member_id_idx ON public.checkins (member_id);
CREATE INDEX checkins_time_idx      ON public.checkins (checked_in_at DESC);


-- ── WORKOUTS ─────────────────────────────────────────────────
-- A workout is a session (e.g. "Push Day, June 16"). It contains sets.

CREATE TABLE public.workouts (
  id               UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  member_id        UUID        NOT NULL REFERENCES public.members(id) ON DELETE CASCADE,
  logged_at        TIMESTAMPTZ DEFAULT NOW(),
  name             TEXT,         -- "Push Day", "Leg Day", etc.
  notes            TEXT,
  duration_minutes INT
);

CREATE INDEX workouts_member_id_idx ON public.workouts (member_id);


-- ── WORKOUT SETS ─────────────────────────────────────────────
-- Each row is one set within a workout (exercise + reps + weight).

CREATE TABLE public.workout_sets (
  id              UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  workout_id      UUID        NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  exercise_name   TEXT        NOT NULL,
  muscle_group    TEXT,
  set_number      INT,
  reps            INT,
  weight          NUMERIC(6,2),
  weight_unit     TEXT        DEFAULT 'lbs'
);

CREATE INDEX workout_sets_workout_id_idx ON public.workout_sets (workout_id);


-- ── EXERCISE LIBRARY ─────────────────────────────────────────
-- Seeded with common exercises. Members can also add custom ones.

CREATE TABLE public.exercises (
  id           UUID    DEFAULT gen_random_uuid() PRIMARY KEY,
  name         TEXT    NOT NULL,
  muscle_group TEXT,
  category     TEXT    DEFAULT 'strength',  -- 'strength', 'cardio', 'flexibility'
  description  TEXT,
  is_custom    BOOLEAN DEFAULT FALSE
);

CREATE INDEX exercises_name_idx         ON public.exercises (name);
CREATE INDEX exercises_muscle_group_idx ON public.exercises (muscle_group);


-- ── STAFF ────────────────────────────────────────────────────
-- Admin and front desk staff accounts.

CREATE TABLE public.staff (
  id       UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id  UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email    TEXT UNIQUE NOT NULL,
  name     TEXT,
  role     TEXT DEFAULT 'staff'  -- 'admin', 'staff'
);


-- ============================================================
-- ROW LEVEL SECURITY
-- Members can only see/edit their own data.
-- Staff bypass RLS using service role key (admin dashboard only).
-- ============================================================

ALTER TABLE public.members      ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checkins     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workouts     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises    ENABLE ROW LEVEL SECURITY;

-- Members: read/update own record
CREATE POLICY "member_select_own"
  ON public.members FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "member_update_own"
  ON public.members FOR UPDATE
  USING (auth.uid() = user_id);

-- Allow the link-account function to update user_id on signup
CREATE POLICY "member_link_account"
  ON public.members FOR UPDATE
  USING (email = (SELECT email FROM auth.users WHERE id = auth.uid()));

-- Check-ins: members insert/read their own
CREATE POLICY "checkin_insert_own"
  ON public.checkins FOR INSERT
  WITH CHECK (
    member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
  );

CREATE POLICY "checkin_select_own"
  ON public.checkins FOR SELECT
  USING (
    member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
  );

-- Workouts: members CRUD their own
CREATE POLICY "workout_select_own"
  ON public.workouts FOR SELECT
  USING (member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid()));

CREATE POLICY "workout_insert_own"
  ON public.workouts FOR INSERT
  WITH CHECK (member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid()));

CREATE POLICY "workout_delete_own"
  ON public.workouts FOR DELETE
  USING (member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid()));

-- Workout sets: inherit from workout ownership
CREATE POLICY "sets_select_own"
  ON public.workout_sets FOR SELECT
  USING (workout_id IN (
    SELECT id FROM public.workouts
    WHERE member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
  ));

CREATE POLICY "sets_insert_own"
  ON public.workout_sets FOR INSERT
  WITH CHECK (workout_id IN (
    SELECT id FROM public.workouts
    WHERE member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
  ));

CREATE POLICY "sets_delete_own"
  ON public.workout_sets FOR DELETE
  USING (workout_id IN (
    SELECT id FROM public.workouts
    WHERE member_id IN (SELECT id FROM public.members WHERE user_id = auth.uid())
  ));

-- Exercises: everyone can read, only admins write
CREATE POLICY "exercises_select_all"
  ON public.exercises FOR SELECT
  USING (TRUE);


-- ============================================================
-- EXERCISE LIBRARY SEED DATA
-- Common exercises across major muscle groups
-- ============================================================

INSERT INTO public.exercises (name, muscle_group, category) VALUES
-- Chest
('Bench Press', 'Chest', 'strength'),
('Incline Bench Press', 'Chest', 'strength'),
('Decline Bench Press', 'Chest', 'strength'),
('Dumbbell Fly', 'Chest', 'strength'),
('Cable Fly', 'Chest', 'strength'),
('Push-Up', 'Chest', 'strength'),
('Dip', 'Chest', 'strength'),
('Chest Press Machine', 'Chest', 'strength'),
('Incline Dumbbell Press', 'Chest', 'strength'),
-- Back
('Deadlift', 'Back', 'strength'),
('Pull-Up', 'Back', 'strength'),
('Chin-Up', 'Back', 'strength'),
('Barbell Row', 'Back', 'strength'),
('Dumbbell Row', 'Back', 'strength'),
('Lat Pulldown', 'Back', 'strength'),
('Seated Cable Row', 'Back', 'strength'),
('T-Bar Row', 'Back', 'strength'),
('Face Pull', 'Back', 'strength'),
('Rack Pull', 'Back', 'strength'),
-- Shoulders
('Overhead Press', 'Shoulders', 'strength'),
('Dumbbell Shoulder Press', 'Shoulders', 'strength'),
('Lateral Raise', 'Shoulders', 'strength'),
('Front Raise', 'Shoulders', 'strength'),
('Rear Delt Fly', 'Shoulders', 'strength'),
('Arnold Press', 'Shoulders', 'strength'),
('Upright Row', 'Shoulders', 'strength'),
('Shrug', 'Shoulders', 'strength'),
-- Legs
('Squat', 'Legs', 'strength'),
('Front Squat', 'Legs', 'strength'),
('Leg Press', 'Legs', 'strength'),
('Romanian Deadlift', 'Legs', 'strength'),
('Leg Curl', 'Legs', 'strength'),
('Leg Extension', 'Legs', 'strength'),
('Lunge', 'Legs', 'strength'),
('Bulgarian Split Squat', 'Legs', 'strength'),
('Hip Thrust', 'Legs', 'strength'),
('Calf Raise', 'Legs', 'strength'),
('Hack Squat', 'Legs', 'strength'),
('Step-Up', 'Legs', 'strength'),
('Good Morning', 'Legs', 'strength'),
-- Arms — Biceps
('Barbell Curl', 'Biceps', 'strength'),
('Dumbbell Curl', 'Biceps', 'strength'),
('Hammer Curl', 'Biceps', 'strength'),
('Preacher Curl', 'Biceps', 'strength'),
('Concentration Curl', 'Biceps', 'strength'),
('Cable Curl', 'Biceps', 'strength'),
('Incline Dumbbell Curl', 'Biceps', 'strength'),
-- Arms — Triceps
('Tricep Pushdown', 'Triceps', 'strength'),
('Skull Crusher', 'Triceps', 'strength'),
('Close-Grip Bench Press', 'Triceps', 'strength'),
('Overhead Tricep Extension', 'Triceps', 'strength'),
('Tricep Kickback', 'Triceps', 'strength'),
('Diamond Push-Up', 'Triceps', 'strength'),
-- Core
('Plank', 'Core', 'strength'),
('Crunch', 'Core', 'strength'),
('Sit-Up', 'Core', 'strength'),
('Leg Raise', 'Core', 'strength'),
('Russian Twist', 'Core', 'strength'),
('Ab Rollout', 'Core', 'strength'),
('Cable Crunch', 'Core', 'strength'),
('Pallof Press', 'Core', 'strength'),
('Hanging Leg Raise', 'Core', 'strength'),
('Side Plank', 'Core', 'strength'),
-- Cardio
('Treadmill', 'Cardio', 'cardio'),
('Elliptical', 'Cardio', 'cardio'),
('Rowing Machine', 'Cardio', 'cardio'),
('Stationary Bike', 'Cardio', 'cardio'),
('Jump Rope', 'Cardio', 'cardio'),
('Stair Climber', 'Cardio', 'cardio'),
('Assault Bike', 'Cardio', 'cardio'),
('Sled Push', 'Cardio', 'cardio'),
('Battle Ropes', 'Cardio', 'cardio'),
-- Full Body / Olympic
('Clean and Jerk', 'Full Body', 'strength'),
('Snatch', 'Full Body', 'strength'),
('Power Clean', 'Full Body', 'strength'),
('Kettlebell Swing', 'Full Body', 'strength'),
('Turkish Get-Up', 'Full Body', 'strength'),
('Farmer Carry', 'Full Body', 'strength'),
('Burpee', 'Full Body', 'cardio'),
('Box Jump', 'Full Body', 'strength');
