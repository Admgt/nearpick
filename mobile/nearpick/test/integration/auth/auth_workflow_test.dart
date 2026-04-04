import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/core/auth/auth_workflow.dart';

import '../../test_helpers/in_memory_workflow_fakes.dart';

void main() {
  test('AuthWorkflow.register persists the user profile', () async {
    final authGateway = FakeAuthGateway();
    final profileGateway = FakeUserProfileGateway();
    final workflow = AuthWorkflow(
      authGateway: authGateway,
      userProfileGateway: profileGateway,
    );

    await workflow.register(
      email: 'merchant@example.com',
      password: 'secret-123',
      displayName: 'Merchant',
      role: 'merchant',
      companyName: 'Penny',
    );

    expect(authGateway.currentUserId, isNotNull);
    expect(profileGateway.profiles[authGateway.currentUserId], {
      'email': 'merchant@example.com',
      'displayName': 'Merchant',
      'role': 'merchant',
      'companyName': 'Penny',
    });
  });

  test('AuthWorkflow.login succeeds with valid credentials', () async {
    final authGateway = FakeAuthGateway();
    final profileGateway = FakeUserProfileGateway();
    final workflow = AuthWorkflow(
      authGateway: authGateway,
      userProfileGateway: profileGateway,
    );

    await workflow.register(
      email: 'user@example.com',
      password: 'correct-password',
      displayName: 'User',
      role: 'consumer',
      companyName: '',
    );
    await authGateway.signOut();

    await workflow.login(
      email: 'user@example.com',
      password: 'correct-password',
    );

    expect(authGateway.currentUserId, 'signed-in-user@example.com');
  });

  test('AuthWorkflow.login fails on invalid credentials', () async {
    final authGateway = FakeAuthGateway();
    final profileGateway = FakeUserProfileGateway();
    final workflow = AuthWorkflow(
      authGateway: authGateway,
      userProfileGateway: profileGateway,
    );

    await workflow.register(
      email: 'user@example.com',
      password: 'correct-password',
      displayName: 'User',
      role: 'consumer',
      companyName: '',
    );
    await authGateway.signOut();

    await expectLater(
      workflow.login(email: 'user@example.com', password: 'wrong-password'),
      throwsA(isA<StateError>()),
    );
    expect(authGateway.currentUserId, isNull);
  });
}
