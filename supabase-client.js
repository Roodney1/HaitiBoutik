/* HaitiBoutik public Supabase client.
 * This file contains only the publishable key. Never place service_role/secret keys here.
 * Database access is restricted by PostgreSQL grants and Row Level Security.
 */
(function () {
  if (!window.supabase || typeof window.supabase.createClient !== "function") {
    console.error("Supabase JS SDK could not be loaded.");
    return;
  }
  window.haitiBoutikSupabase = window.supabase.createClient(
    "https://wlpbblnerlhsabxuncta.supabase.co",
    "sb_publishable_B6vB3Spd4Qq3n8K_2PcYXw_hzMxJnA1"
  );
})();