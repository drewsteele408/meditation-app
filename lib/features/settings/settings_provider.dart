import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/supabase_provider.dart';

part 'settings_provider.g.dart';

/// A simple data class holding the fields the Settings screen needs to display.
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
  });

  final String displayName;
  final String email;
}

/// Fetches the current user's [displayName] from the `profiles` table and
/// their [email] from the authenticated Supabase user object.
///
/// Returns a [UserProfile] with empty strings for any absent fields so the
/// screen can always render without crashing.
@riverpod
Future<UserProfile> userProfile(UserProfileRef ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;

  if (user == null) {
    return const UserProfile(displayName: '', email: '');
  }

  final response = await supabase
      .from('profiles')
      .select('display_name')
      .eq('id', user.id)
      .single();

  final displayName = (response['display_name'] as String?) ?? '';
  final email = user.email ?? '';

  return UserProfile(displayName: displayName, email: email);
}
