import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nearpick/main.dart';

void main() {
  testWidgets(
    'RootRouter waits for the profile role and then opens merchant home',
    (tester) async {
      final userIdController = StreamController<String?>();
      final roleController = StreamController<String?>();
      var notificationInitCalls = 0;

      addTearDown(userIdController.close);
      addTearDown(roleController.close);

      await tester.pumpWidget(
        MaterialApp(
          home: RootRouter(
            userIdChanges: () => userIdController.stream,
            roleChanges: (_) => roleController.stream,
            loginScreenBuilder: (_) => const Text('login'),
            consumerHomeBuilder: (_) => const Text('consumer-home'),
            merchantHomeBuilder: (_) => const Text('merchant-home'),
            notificationInitializer: () async {
              notificationInitCalls += 1;
            },
          ),
        ),
      );

      userIdController.add('merchant-user');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('consumer-home'), findsNothing);
      expect(find.text('merchant-home'), findsNothing);

      roleController.add(null);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('consumer-home'), findsNothing);

      roleController.add('merchant');
      await tester.pump();

      expect(find.text('merchant-home'), findsOneWidget);
      expect(find.text('consumer-home'), findsNothing);
      expect(notificationInitCalls, 1);
    },
  );

  testWidgets('RootRouter opens admin home for admin session', (tester) async {
    final userIdController = StreamController<String?>();
    final sessionController = StreamController<SessionAccess?>();

    addTearDown(userIdController.close);
    addTearDown(sessionController.close);

    await tester.pumpWidget(
      MaterialApp(
        home: RootRouter(
          userIdChanges: () => userIdController.stream,
          sessionChanges: (_) => sessionController.stream,
          loginScreenBuilder: (_) => const Text('login'),
          adminHomeBuilder: (_) => const Text('admin-home'),
          notificationInitializer: () async {},
        ),
      ),
    );

    userIdController.add('admin-user');
    await tester.pump();
    sessionController.add(
      const SessionAccess(role: 'admin', accountStatus: 'active'),
    );
    await tester.pump();

    expect(find.text('admin-home'), findsOneWidget);
  });

  testWidgets('RootRouter shows restricted screen for blocked account', (
    tester,
  ) async {
    final userIdController = StreamController<String?>();
    final sessionController = StreamController<SessionAccess?>();

    addTearDown(userIdController.close);
    addTearDown(sessionController.close);

    await tester.pumpWidget(
      MaterialApp(
        home: RootRouter(
          userIdChanges: () => userIdController.stream,
          sessionChanges: (_) => sessionController.stream,
          accountStatusScreenBuilder: (_, status) => Text('restricted-$status'),
          notificationInitializer: () async {},
        ),
      ),
    );

    userIdController.add('blocked-user');
    await tester.pump();
    sessionController.add(
      const SessionAccess(role: 'consumer', accountStatus: 'blocked'),
    );
    await tester.pump();

    expect(find.text('restricted-blocked'), findsOneWidget);
  });
}
