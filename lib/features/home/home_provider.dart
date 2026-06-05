import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/supabase_provider.dart';

part 'home_provider.g.dart';

/// Fetches the current user's display_name from the `profiles` table.
///
/// Returns an empty string if the user is not authenticated or the field is
/// absent, so the screen can always render without crashing.
@riverpod
Future<String> userDisplayName(UserDisplayNameRef ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = supabase.auth.currentUser?.id;

  if (userId == null) return '';

  final response = await supabase
      .from('profiles')
      .select('display_name')
      .eq('id', userId)
      .single();

  return (response['display_name'] as String?) ?? '';
}
