-- ============================================================
-- SUPABASE CANONICAL SCHEMA - Hyperlocal Emergency Registry
-- ============================================================
-- Purpose:
-- 1. Rebuild the volunteers table with a clean, consistent contract
-- 2. Enforce safe defaults and validation for registration
-- 3. Keep map/presence features working with optional location columns
-- 4. Lock down direct table access with RLS and expose safe RPCs

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DROP FUNCTION IF EXISTS public.get_volunteers_with_location(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.update_volunteer_location(UUID, DOUBLE PRECISION, DOUBLE PRECISION);
DROP FUNCTION IF EXISTS public.toggle_location_sharing(UUID, BOOLEAN);
DROP FUNCTION IF EXISTS public.search_volunteers(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.get_volunteer_profile(UUID);
DROP FUNCTION IF EXISTS public.update_volunteer_availability(UUID, TEXT, BOOLEAN);
DROP FUNCTION IF EXISTS public.register_volunteer(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT[], TEXT, BOOLEAN, DOUBLE PRECISION, DOUBLE PRECISION);

DROP TABLE IF EXISTS public.volunteers CASCADE;

CREATE TABLE public.volunteers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  locality TEXT NOT NULL,
  city TEXT NOT NULL,
  state TEXT NOT NULL,
  skills TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  availability TEXT NOT NULL DEFAULT 'available_now',
  consent_given BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  last_updated TIMESTAMPTZ,
  is_location_shared BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT volunteers_name_not_blank CHECK (btrim(name) <> ''),
  CONSTRAINT volunteers_phone_not_blank CHECK (btrim(phone) <> ''),
  CONSTRAINT volunteers_locality_not_blank CHECK (btrim(locality) <> ''),
  CONSTRAINT volunteers_city_not_blank CHECK (btrim(city) <> ''),
  CONSTRAINT volunteers_state_not_blank CHECK (btrim(state) <> ''),
  CONSTRAINT volunteers_skills_non_empty CHECK (cardinality(skills) > 0),
  CONSTRAINT volunteers_availability_valid CHECK (
    availability IN ('available_now', 'within_30_min', 'busy')
  ),
  CONSTRAINT volunteers_location_pair CHECK (
    (latitude IS NULL AND longitude IS NULL) OR
    (latitude IS NOT NULL AND longitude IS NOT NULL)
  ),
  CONSTRAINT volunteers_location_share_requires_coordinates CHECK (
    NOT is_location_shared OR (latitude IS NOT NULL AND longitude IS NOT NULL)
  ),
  CONSTRAINT volunteers_phone_unique UNIQUE (phone)
);

CREATE INDEX idx_volunteers_locality ON public.volunteers (locality);
CREATE INDEX idx_volunteers_city ON public.volunteers (city);
CREATE INDEX idx_volunteers_availability ON public.volunteers (availability);
CREATE INDEX idx_volunteers_location_shared
  ON public.volunteers (is_location_shared)
  WHERE is_location_shared = TRUE;
CREATE INDEX idx_volunteers_coordinates
  ON public.volunteers (latitude, longitude)
  WHERE is_location_shared = TRUE
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL;

ALTER TABLE public.volunteers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.volunteers FORCE ROW LEVEL SECURITY;

REVOKE ALL ON public.volunteers FROM anon, authenticated, PUBLIC;
GRANT INSERT, SELECT ON public.volunteers TO anon, authenticated;

CREATE POLICY volunteers_insert_with_explicit_consent
ON public.volunteers
FOR INSERT
TO anon, authenticated
WITH CHECK (
  consent_given = TRUE
  AND btrim(name) <> ''
  AND btrim(phone) <> ''
  AND btrim(locality) <> ''
  AND btrim(city) <> ''
  AND btrim(state) <> ''
  AND cardinality(skills) > 0
  AND availability IN ('available_now', 'within_30_min', 'busy')
);

CREATE POLICY volunteers_select_consented_rows
ON public.volunteers
FOR SELECT
TO anon, authenticated
USING (consent_given = TRUE);

CREATE OR REPLACE FUNCTION public.update_volunteer_location(
  p_volunteer_id UUID,
  p_latitude DOUBLE PRECISION,
  p_longitude DOUBLE PRECISION
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated RECORD;
BEGIN
  UPDATE public.volunteers
  SET
    latitude = p_latitude,
    longitude = p_longitude,
    last_updated = timezone('utc', now()),
    is_location_shared = consent_given AND availability <> 'busy'
  WHERE id = p_volunteer_id
  RETURNING id, last_updated, is_location_shared
  INTO v_updated;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Volunteer not found'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'volunteer_id', v_updated.id,
    'updated_at', v_updated.last_updated,
    'is_location_shared', v_updated.is_location_shared
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.toggle_location_sharing(
  p_volunteer_id UUID,
  p_is_location_shared BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_updated RECORD;
BEGIN
  UPDATE public.volunteers
  SET
    is_location_shared = CASE
      WHEN p_is_location_shared
        THEN consent_given AND availability <> 'busy' AND latitude IS NOT NULL AND longitude IS NOT NULL
      ELSE FALSE
    END
  WHERE id = p_volunteer_id
  RETURNING id, is_location_shared
  INTO v_updated;

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Volunteer not found'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'volunteer_id', v_updated.id,
    'is_location_shared', v_updated.is_location_shared
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.search_volunteers(
  p_locality TEXT DEFAULT NULL,
  p_skill TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'volunteers',
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'id', v.id,
            'name', v.name,
            'phone', v.phone,
            'locality', v.locality,
            'city', v.city,
            'state', v.state,
            'skills', v.skills,
            'availability', v.availability,
            'consent_given', v.consent_given,
            'created_at', v.created_at,
            'latitude', v.latitude,
            'longitude', v.longitude,
            'last_updated', v.last_updated,
            'is_location_shared', v.is_location_shared
          )
          ORDER BY v.created_at DESC
        ),
        '[]'::jsonb
      ),
      'total',
      COUNT(*)
    )
    FROM public.volunteers v
    WHERE v.consent_given = TRUE
      AND (p_locality IS NULL OR v.locality ILIKE '%' || btrim(p_locality) || '%')
      AND (
        p_skill IS NULL
        OR EXISTS (
          SELECT 1
          FROM unnest(v.skills) AS skill
          WHERE skill ILIKE '%' || btrim(p_skill) || '%'
        )
      )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_volunteers_with_location(
  p_locality TEXT DEFAULT NULL,
  p_user_latitude DOUBLE PRECISION DEFAULT NULL,
  p_user_longitude DOUBLE PRECISION DEFAULT NULL,
  p_radius_km DOUBLE PRECISION DEFAULT 50.0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN (
    SELECT jsonb_build_object(
      'volunteers',
      COALESCE(
        jsonb_agg(
          jsonb_build_object(
            'id', v.id,
            'name', v.name,
            'phone', v.phone,
            'locality', v.locality,
            'city', v.city,
            'state', v.state,
            'skills', v.skills,
            'availability', v.availability,
            'consent_given', v.consent_given,
            'created_at', v.created_at,
            'latitude', v.latitude,
            'longitude', v.longitude,
            'last_updated', v.last_updated,
            'is_location_shared', v.is_location_shared,
            'distance_km',
            CASE
              WHEN p_user_latitude IS NOT NULL
                AND p_user_longitude IS NOT NULL
              THEN ROUND(
                (
                  111.198 * SQRT(
                    POW(v.latitude - p_user_latitude, 2) +
                    POW(
                      (v.longitude - p_user_longitude) * COS(RADIANS(p_user_latitude)),
                      2
                    )
                  )
                )::NUMERIC,
                2
              )::DOUBLE PRECISION
              ELSE NULL
            END
          )
          ORDER BY
            CASE
              WHEN p_user_latitude IS NOT NULL AND p_user_longitude IS NOT NULL
              THEN 111.198 * SQRT(
                POW(v.latitude - p_user_latitude, 2) +
                POW((v.longitude - p_user_longitude) * COS(RADIANS(p_user_latitude)), 2)
              )
              ELSE 999999
            END ASC,
            v.created_at DESC
        ),
        '[]'::jsonb
      ),
      'total',
      COUNT(*)
    )
    FROM public.volunteers v
    WHERE v.consent_given = TRUE
      AND v.is_location_shared = TRUE
      AND v.latitude IS NOT NULL
      AND v.longitude IS NOT NULL
      AND (p_locality IS NULL OR v.locality ILIKE '%' || btrim(p_locality) || '%')
      AND (
        p_user_latitude IS NULL
        OR p_user_longitude IS NULL
        OR (
          111.198 * SQRT(
            POW(v.latitude - p_user_latitude, 2) +
            POW((v.longitude - p_user_longitude) * COS(RADIANS(p_user_latitude)), 2)
          )
        ) <= p_radius_km
      )
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.get_volunteer_profile(
  p_volunteer_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile JSONB;
BEGIN
  SELECT jsonb_build_object(
    'id', v.id,
    'name', v.name,
    'phone', v.phone,
    'locality', v.locality,
    'city', v.city,
    'state', v.state,
    'skills', v.skills,
    'availability', v.availability,
    'consent_given', v.consent_given,
    'created_at', v.created_at,
    'latitude', v.latitude,
    'longitude', v.longitude,
    'last_updated', v.last_updated,
    'is_location_shared', v.is_location_shared
  )
  INTO v_profile
  FROM public.volunteers v
  WHERE v.id = p_volunteer_id;

  IF v_profile IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Volunteer not found'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'volunteer', v_profile
  );
END;
$$;

CREATE OR REPLACE FUNCTION public.update_volunteer_availability(
  p_volunteer_id UUID,
  p_availability TEXT,
  p_is_location_shared BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_profile JSONB;
BEGIN
  UPDATE public.volunteers
  SET
    availability = p_availability,
    is_location_shared = CASE
      WHEN p_is_location_shared
        THEN consent_given AND p_availability <> 'busy' AND latitude IS NOT NULL AND longitude IS NOT NULL
      ELSE FALSE
    END
  WHERE id = p_volunteer_id
  RETURNING jsonb_build_object(
    'id', id,
    'name', name,
    'phone', phone,
    'locality', locality,
    'city', city,
    'state', state,
    'skills', skills,
    'availability', availability,
    'consent_given', consent_given,
    'created_at', created_at,
    'latitude', latitude,
    'longitude', longitude,
    'last_updated', last_updated,
    'is_location_shared', is_location_shared
  )
  INTO v_profile;

  IF v_profile IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Volunteer not found'
    );
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'volunteer', v_profile
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_volunteer_location(UUID, DOUBLE PRECISION, DOUBLE PRECISION) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.toggle_location_sharing(UUID, BOOLEAN) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.search_volunteers(TEXT, TEXT) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_volunteers_with_location(TEXT, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_volunteer_profile(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.update_volunteer_availability(UUID, TEXT, BOOLEAN) TO anon, authenticated;

COMMIT;

-- Notes:
-- 1. Registration is a direct insert into public.volunteers from Flutter.
-- 2. consent_given is NOT NULL with default FALSE, but RLS only allows inserts when it is TRUE.
-- 3. Search/profile/map/presence operations use SECURITY DEFINER RPCs so the app never needs broad table read/update access.
