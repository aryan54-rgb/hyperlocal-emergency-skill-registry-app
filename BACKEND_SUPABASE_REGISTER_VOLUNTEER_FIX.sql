-- ============================================================
-- SUPABASE REPAIR PATCH - Existing deployments
-- ============================================================
-- Use this when you already have a public.volunteers table and want to
-- repair it without dropping production data.
--
-- For a clean reset, run BACKEND_SUPABASE_MIGRATIONS.sql instead.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE public.volunteers
  ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS locality TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS state TEXT,
  ADD COLUMN IF NOT EXISTS skills TEXT[] DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS availability TEXT DEFAULT 'available_now',
  ADD COLUMN IF NOT EXISTS consent_given BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT timezone('utc', now()),
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS last_updated TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS is_location_shared BOOLEAN DEFAULT FALSE;

UPDATE public.volunteers
SET
  skills = COALESCE(skills, ARRAY[]::TEXT[]),
  availability = COALESCE(NULLIF(btrim(availability), ''), 'available_now'),
  consent_given = COALESCE(consent_given, FALSE),
  created_at = COALESCE(created_at, timezone('utc', now())),
  is_location_shared = COALESCE(is_location_shared, FALSE);

ALTER TABLE public.volunteers
  ALTER COLUMN id SET DEFAULT gen_random_uuid(),
  ALTER COLUMN name SET NOT NULL,
  ALTER COLUMN phone SET NOT NULL,
  ALTER COLUMN locality SET NOT NULL,
  ALTER COLUMN city SET NOT NULL,
  ALTER COLUMN state SET NOT NULL,
  ALTER COLUMN skills SET DEFAULT ARRAY[]::TEXT[],
  ALTER COLUMN skills SET NOT NULL,
  ALTER COLUMN availability SET DEFAULT 'available_now',
  ALTER COLUMN availability SET NOT NULL,
  ALTER COLUMN consent_given SET DEFAULT FALSE,
  ALTER COLUMN consent_given SET NOT NULL,
  ALTER COLUMN created_at SET DEFAULT timezone('utc', now()),
  ALTER COLUMN created_at SET NOT NULL,
  ALTER COLUMN is_location_shared SET DEFAULT FALSE,
  ALTER COLUMN is_location_shared SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_pkey'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_pkey PRIMARY KEY (id);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_name_not_blank'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_name_not_blank CHECK (btrim(name) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_phone_not_blank'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_phone_not_blank CHECK (btrim(phone) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_locality_not_blank'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_locality_not_blank CHECK (btrim(locality) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_city_not_blank'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_city_not_blank CHECK (btrim(city) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_state_not_blank'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_state_not_blank CHECK (btrim(state) <> '');
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_skills_non_empty'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_skills_non_empty CHECK (cardinality(skills) > 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_availability_valid'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_availability_valid CHECK (
        availability IN ('available_now', 'within_30_min', 'busy')
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_location_pair'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_location_pair CHECK (
        (latitude IS NULL AND longitude IS NULL) OR
        (latitude IS NOT NULL AND longitude IS NOT NULL)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_location_share_requires_coordinates'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_location_share_requires_coordinates CHECK (
        NOT is_location_shared OR (latitude IS NOT NULL AND longitude IS NOT NULL)
      );
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'volunteers_phone_unique'
  ) THEN
    ALTER TABLE public.volunteers
      ADD CONSTRAINT volunteers_phone_unique UNIQUE (phone);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_volunteers_location_shared
  ON public.volunteers (is_location_shared)
  WHERE is_location_shared = TRUE;

CREATE INDEX IF NOT EXISTS idx_volunteers_coordinates
  ON public.volunteers (latitude, longitude)
  WHERE is_location_shared = TRUE
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL;

COMMIT;

-- After this repair patch, run BACKEND_SUPABASE_MIGRATIONS.sql to refresh
-- RLS policies and RPCs so the Flutter client and database are fully aligned.
