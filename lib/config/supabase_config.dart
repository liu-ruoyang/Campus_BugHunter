class SupabaseConfig {
  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nsbnuaotpqgqwjwqnfbz.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_DRVhDTPA_V7UfvtJQuTxug_6dPBKObQ',
  );
  static const bucket = String.fromEnvironment(
    'SUPABASE_STORAGE_BUCKET',
    defaultValue: 'bounty-images',
  );

  static bool get isConfigured => url.isNotEmpty && publishableKey.isNotEmpty;
}
