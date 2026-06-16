-- Migrazione: harden_admin_plan_enum_invite_enum_seo_views
-- Applicata a Supabase project amzjefyegfxkpzjifynj (LIVE) il 2026-06-16
-- Scopo: correzione 3 criticita' reali emerse dall'audit di produzione.
-- Tutte CREATE OR REPLACE / ALTER VIEW: atomiche, reversibili, zero impatto sui dati.

-- ─────────────────────────────────────────────────────────────────────────
-- FIX #1 (Medium funzionale) — admin_update_user_plan
-- Problema: il CHECK accettava solo 'free'|'pro', ma i piani 'pro_plus'|'agency'
--           esistono e sono in uso (il webhook Stripe li scrive). Un super_admin
--           non poteva impostarli manualmente -> RAISE 'INVALID_PLAN'.
-- Fix: enum esteso. Guard super_admin invariato.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.admin_update_user_plan(target_user_id uuid, new_plan text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE caller_role TEXT;
BEGIN
  SELECT p.role INTO caller_role FROM public.profiles p WHERE p.id = auth.uid();
  IF caller_role != 'super_admin' THEN
    RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;
  IF new_plan NOT IN ('free','pro','pro_plus','agency') THEN
    RAISE EXCEPTION 'INVALID_PLAN: free|pro|pro_plus|agency';
  END IF;
  UPDATE public.profiles SET plan = new_plan, updated_at = NOW() WHERE id = target_user_id;
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- FIX #2 (High) — check_user_exists_by_email
-- Problema: oracolo di user-enumeration callable da QUALSIASI utente autenticato
--           (ritornava l'esistenza di un'email arbitraria su auth.users).
-- Fix: guard — solo proprietari di workspace (inviter legittimi) possono chiamarla.
--      Firma invariata (text -> boolean), il fallback try/catch del client resta valido.
-- ─────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.check_user_exists_by_email(p_email text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE is_inviter boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM public.workspaces w WHERE w.owner_id = auth.uid()) INTO is_inviter;
  IF NOT is_inviter THEN
    RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;
  RETURN EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = lower(p_email));
END;
$function$;

-- ─────────────────────────────────────────────────────────────────────────
-- FIX #3 (Low / lint ERROR security_definer_view) — view seo_v_*
-- Problema: 3 view SECURITY DEFINER bypassavano la RLS del creatore (lint ERROR).
--           Non concesse ad anon/authenticated (non esposte via API), ma per
--           least-privilege passano a security_invoker. Nessun cambio comportamento API.
-- Requisito: PostgreSQL >= 15 (Supabase ok).
-- ─────────────────────────────────────────────────────────────────────────
ALTER VIEW public.seo_v_latest_status  SET (security_invoker = on);
ALTER VIEW public.seo_v_weekly_trend   SET (security_invoker = on);
ALTER VIEW public.seo_v_not_indexed_7d SET (security_invoker = on);
