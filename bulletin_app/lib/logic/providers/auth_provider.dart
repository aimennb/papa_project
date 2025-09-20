import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

class UserAccount {
  const UserAccount({required this.id, required this.email, required this.role});

  final String id;
  final String email;
  final UserRole role;

  UserAccount copyWith({String? id, String? email, UserRole? role}) {
    return UserAccount(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }
}

class CurrentUserNotifier extends StateNotifier<UserAccount> {
  CurrentUserNotifier()
      : super(const UserAccount(
          id: 'local-user', email: 'demo@bulletin.app', role: UserRole.admin));

  void setRole(UserRole role) {
    state = state.copyWith(role: role);
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserAccount>((ref) {
  return CurrentUserNotifier();
});
