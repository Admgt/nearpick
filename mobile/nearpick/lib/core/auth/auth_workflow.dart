class AuthIdentity {
  final String uid;
  final String email;

  const AuthIdentity({required this.uid, required this.email});
}

abstract class AuthGateway {
  String? get currentUserId;

  Future<AuthIdentity> createUser({
    required String email,
    required String password,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

abstract class UserProfileGateway {
  Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String displayName,
    required String role,
  });
}

class AuthWorkflow {
  final AuthGateway authGateway;
  final UserProfileGateway userProfileGateway;

  const AuthWorkflow({
    required this.authGateway,
    required this.userProfileGateway,
  });

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    final identity = await authGateway.createUser(
      email: email,
      password: password,
    );
    await userProfileGateway.saveUserProfile(
      uid: identity.uid,
      email: email,
      displayName: displayName,
      role: role,
    );
  }

  Future<void> login({required String email, required String password}) {
    return authGateway.signIn(email: email, password: password);
  }

  Future<void> logout() {
    return authGateway.signOut();
  }
}
