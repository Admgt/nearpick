import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nearpick/services/auth_service.dart';
import 'firebase_options.dart';
import 'features/auth/login_screen.dart';
import 'features/consumer/consumer_home_screen.dart';
import 'features/merchant/merchant_home_screen.dart';
import 'services/notification_service.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  bool _tokenInitDone = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        // ha be van jelentkezve, nézzük meg a szerepkört
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snap.data!.data() as Map<String, dynamic>?;
            final role = data?['role'] as String? ?? 'consumer';

            if (!_tokenInitDone) {
              _tokenInitDone = true;
              NotificationService().initAndSaveToken(
                vapidKey:
                    'BJQgYIGTpei0KVzMliZ2mqoPMiY3N2UGYCa_-PiPjnE0kXE0Rv72x6BI6TPYVdLUxf7aLioCRsRIu0pN8Vp-YVM',
              );
            }

            if (role == 'merchant') {
              return const MerchantHomeScreen();
            } else {
              return const ConsumerHomeScreen();
            }
          },
        );
      },
    );
  }
}
