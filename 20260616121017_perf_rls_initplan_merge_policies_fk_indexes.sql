-- Migrazione: perf_rls_initplan_merge_policies_fk_indexes
-- Applicata a Supabase project amzjefyegfxkpzjifynj (LIVE) il 2026-06-16
-- Ottimizzazioni performance a scala. ZERO cambio di semantica o di accesso.
-- ALTER POLICY = riscrittura in-place (nessuna finestra senza RLS).
--
-- Risultato advisor: auth_rls_initplan (28) + multiple_permissive (10)
-- + duplicate_index (1) + unindexed_fk (5) => tutti risolti.
-- Restano solo lint INFO unused_index (falsi positivi da basso traffico).

-- 1) auth_rls_initplan: auth.uid()/auth.email() -> (select ...) [1 eval/query invece di 1/riga]
ALTER POLICY brand_settings_delete_own ON public.brand_settings USING (((select auth.uid()) = user_id));
ALTER POLICY brand_settings_insert_own ON public.brand_settings WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY brand_settings_select_own ON public.brand_settings USING (((select auth.uid()) = user_id));
ALTER POLICY brand_settings_update_own ON public.brand_settings USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY categories_delete_own ON public.categories USING ((((select auth.uid()) = user_id) AND (is_system = false)));
ALTER POLICY categories_read ON public.categories USING (((is_system = true) OR ((select auth.uid()) = user_id)));
ALTER POLICY categories_update_own ON public.categories USING ((((select auth.uid()) = user_id) AND (is_system = false))) WITH CHECK ((((select auth.uid()) = user_id) AND (is_system = false)));
ALTER POLICY categories_write ON public.categories WITH CHECK ((((select auth.uid()) = user_id) AND (is_system = false)));
ALTER POLICY pv_delete_own ON public.project_versions USING (((select auth.uid()) = user_id));
ALTER POLICY pv_insert_own ON public.project_versions WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY pv_select_own ON public.project_versions USING (((select auth.uid()) = user_id));
ALTER POLICY pv_update_own ON public.project_versions USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY properties_delete_own ON public.properties USING (((select auth.uid()) = user_id));
ALTER POLICY properties_insert_own ON public.properties WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY properties_select_own ON public.properties USING (((select auth.uid()) = user_id));
ALTER POLICY properties_update_own ON public.properties USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY transactions_delete_own ON public.transactions USING (((select auth.uid()) = user_id));
ALTER POLICY transactions_insert ON public.transactions WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY transactions_own ON public.transactions USING ((((select auth.uid()) = user_id) AND (deleted_at IS NULL)));
ALTER POLICY transactions_update_own ON public.transactions USING (((select auth.uid()) = user_id)) WITH CHECK (((select auth.uid()) = user_id));
ALTER POLICY ws_delete_owner ON public.workspaces USING ((owner_id = (select auth.uid())));
ALTER POLICY ws_insert_owner ON public.workspaces WITH CHECK ((owner_id = (select auth.uid())));
ALTER POLICY ws_update_owner ON public.workspaces USING ((owner_id = (select auth.uid()))) WITH CHECK ((owner_id = (select auth.uid())));
ALTER POLICY wm_delete_admin_or_self ON public.workspace_members USING (((user_id = (select auth.uid())) OR (workspace_id IN ( SELECT get_my_owner_workspace_ids() AS get_my_owner_workspace_ids))));
ALTER POLICY wi_update_status ON public.workspace_invites
  USING (((workspace_id IN ( SELECT get_my_admin_workspace_ids() AS get_my_admin_workspace_ids)) OR ((lower(invited_email) = lower(COALESCE((select auth.email()), ''::text))) AND (status = 'pending'::text))))
  WITH CHECK ((status = ANY (ARRAY['accepted'::text, 'declined'::text, 'expired'::text])));

-- 2) multiple_permissive_policies: merge coppie SELECT ridondanti (OR equivalente)
DROP POLICY ws_select_member ON public.workspaces;
DROP POLICY ws_select_owner ON public.workspaces;
CREATE POLICY ws_select ON public.workspaces FOR SELECT
  USING (((id IN ( SELECT get_my_workspace_ids() AS get_my_workspace_ids)) OR (owner_id = (select auth.uid()))));
DROP POLICY wi_select_admin ON public.workspace_invites;
DROP POLICY wi_select_invitee ON public.workspace_invites;
CREATE POLICY wi_select ON public.workspace_invites FOR SELECT
  USING (((workspace_id IN ( SELECT get_my_admin_workspace_ids() AS get_my_admin_workspace_ids)) OR ((lower(invited_email) = lower(COALESCE((select auth.email()), ''::text))) AND (status = 'pending'::text))));

-- 3) duplicate_index: drop vincolo UNIQUE ridondante (mantengo wm_unique)
ALTER TABLE public.workspace_members DROP CONSTRAINT IF EXISTS workspace_members_workspace_id_user_id_key;

-- 4) unindexed_foreign_keys: indici di copertura
CREATE INDEX IF NOT EXISTS idx_categories_user_id          ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_category_id     ON public.transactions(category_id);
CREATE INDEX IF NOT EXISTS idx_seo_alerts_site_id           ON public.seo_alerts(site_id);
CREATE INDEX IF NOT EXISTS idx_seo_alerts_url_id            ON public.seo_alerts(url_id);
CREATE INDEX IF NOT EXISTS idx_workspace_invites_invited_by ON public.workspace_invites(invited_by);
