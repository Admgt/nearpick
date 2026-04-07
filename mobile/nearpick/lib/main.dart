import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nearpick/services/auth_service.dart';
import 'app_config.dart';
import 'firebase_options.dart';
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
    this.loginScreenBuilder,
    this.consumerHomeBuilder,
    this.merchantHomeBuilder,
    this.notificationInitializer,
  });

  final Stream<String?> Function()? userIdChanges;
  final Stream<String?> Function(String userId)? roleChanges;
  final WidgetBuilder? loginScreenBuilder;
  final WidgetBuilder? consumerHomeBuilder;
  final WidgetBuilder? merchantHomeBuilder;
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

        // ha be van jelentkezve, nézzük meg a szerepkört
        return StreamBuilder<String?>(
          stream: _roleChanges(userId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting ||
                !snap.hasData) {
              return const _LoadingScreen();
            }

            final role = snap.data! == 'merchant' ? 'merchant' : 'consumer';

            if (!_tokenInitDone) {
              _tokenInitDone = true;
              _initializeNotifications();
            }

            if (role == 'merchant') {
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

  Stream<String?> _roleChanges(String userId) {
    final provider = widget.roleChanges;
    if (provider != null) {
      return provider(userId);
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          final data = snapshot.data();
          return data?['role'] as String? ?? 'consumer';
        });
  }

  Widget _buildLoginScreen(BuildContext context) =>
      widget.loginScreenBuilder?.call(context) ?? const LoginScreen();

  Widget _buildConsumerHome(BuildContext context) =>
      widget.consumerHomeBuilder?.call(context) ?? const ConsumerHomeScreen();

  Widget _buildMerchantHome(BuildContext context) =>
      widget.merchantHomeBuilder?.call(context) ?? const MerchantHomeScreen();

  void _initializeNotifications() {
    final initializer = widget.notificationInitializer;
    if (initializer != null) {
      initializer();
      return;
    }

    NotificationService().initAndSaveToken(vapidKey: AppConfig.webPushVapidKey);
  }
}
