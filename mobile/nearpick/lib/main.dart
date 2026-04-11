import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nearpick/services/auth_service.dart';
import 'app_config.dart';
import 'firebase_options.dart';
import 'features/admin/admin_home_screen.dart';
import 'features/auth/account_status_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/consumer/consumer_home_screen.dart';
import 'features/merchant/merchant_home_screen.dart';
import 'services/notification_service.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AppConfig.configureFirebaseRuntime();
  runApp(const NearPickApp());
}

class NearPickApp extends StatelessWidget {
  const NearPickApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearPick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RootRouter(),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class RootRouter extends StatefulWidget {
  const RootRouter({
    super.key,
    this.userIdChanges,
    this.roleChanges,
    this.sessionChanges,
    this.loginScreenBuilder,
    this.adminHomeBuilder,
    this.consumerHomeBuilder,
    this.merchantHomeBuilder,
    this.accountStatusScreenBuilder,
    this.notificationInitializer,
  });

  final Stream<String?> Function()? userIdChanges;
  final Stream<String?> Function(String userId)? roleChanges;
  final Stream<SessionAccess?> Function(String userId)? sessionChanges;
  final WidgetBuilder? loginScreenBuilder;
  final WidgetBuilder? adminHomeBuilder;
  final WidgetBuilder? consumerHomeBuilder;
  final WidgetBuilder? merchantHomeBuilder;
  final Widget Function(BuildContext context, String accountStatus)?
  accountStatusScreenBuilder;
  final Future<void> Function()? notificationInitializer;

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _tokenInitDone = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _userIdChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final userId = snapshot.data;
        if (userId == null) {
          return _buildLoginScreen(context);
        }

        return StreamBuilder<SessionAccess?>(
          stream: _sessionChanges(userId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting ||
                !snap.hasData) {
              return const _LoadingScreen();
            }

            final session = snap.data!;
            if (session.accountStatus != 'active') {
              return _buildAccountStatusScreen(context, session.accountStatus);
            }

            if (!_tokenInitDone) {
              _tokenInitDone = true;
              _initializeNotifications();
            }

            if (session.role == 'admin') {
              return _buildAdminHome(context);
            }

            if (session.role == 'merchant') {
              return _buildMerchantHome(context);
            }

            return _buildConsumerHome(context);
          },
        );
      },
    );
  }

  Stream<String?> _userIdChanges() {
    final provider = widget.userIdChanges;
    if (provider != null) {
      return provider();
    }

    return AuthService().authStateChanges().map((user) => user?.uid);
  }

  Stream<SessionAccess?> _sessionChanges(String userId) {
    final provider = widget.sessionChanges;
    if (provider != null) {
      return provider(userId);
    }

    final roleProvider = widget.roleChanges;
    if (roleProvider != null) {
      return roleProvider(userId).map((role) {
        if (role == null) {
          return null;
        }
        return SessionAccess(role: role, accountStatus: 'active');
      });
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
          final data = snapshot.data() ?? const <String, dynamic>{};
          final firestoreRole = data['role'] as String? ?? 'consumer';
          final accountStatus = data['accountStatus'] as String? ?? 'active';
          final tokenResult = await AuthService().auth.currentUser
              ?.getIdTokenResult(true);
          final claims = tokenResult?.claims ?? const <String, dynamic>{};
          final hasAdminClaim = claims['admin'] == true;

          return SessionAccess(
            role: hasAdminClaim ? 'admin' : firestoreRole,
            accountStatus: accountStatus,
          );
        });
  }

  Widget _buildLoginScreen(BuildContext context) =>
      widget.loginScreenBuilder?.call(context) ?? const LoginScreen();

  Widget _buildAdminHome(BuildContext context) =>
      widget.adminHomeBuilder?.call(context) ?? const AdminHomeScreen();

  Widget _buildConsumerHome(BuildContext context) =>
      widget.consumerHomeBuilder?.call(context) ?? const ConsumerHomeScreen();

  Widget _buildMerchantHome(BuildContext context) =>
      widget.merchantHomeBuilder?.call(context) ?? const MerchantHomeScreen();

  Widget _buildAccountStatusScreen(BuildContext context, String accountStatus) {
    final builder = widget.accountStatusScreenBuilder;
    if (builder != null) {
      return builder(context, accountStatus);
    }

    return AccountStatusScreen(accountStatus: accountStatus);
  }

  void _initializeNotifications() {
    final initializer = widget.notificationInitializer;
    if (initializer != null) {
      initializer();
      return;
    }

    NotificationService().initAndSaveToken(vapidKey: AppConfig.webPushVapidKey);
  }
}

class SessionAccess {
  final String role;
  final String accountStatus;

  const SessionAccess({required this.role, required this.accountStatus});
}
