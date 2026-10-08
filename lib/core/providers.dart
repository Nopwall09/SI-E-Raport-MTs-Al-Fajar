import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Hanya dibaca saat `USE_FAKE_API=false`, setelah `Supabase.initialize`.
/// Repository memakai ini; layar tidak boleh memanggil Supabase langsung.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
