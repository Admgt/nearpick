import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nearpick/features/auth/login_screen.dart';
import 'package:nearpick/features/auth/register_screen.dart';
import 'package:nearpick/features/merchant/new_product_form_logic.dart';
import 'package:nearpick/features/merchant/new_product_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'merchant registration, login and product save flow works through real UI screens',
    (tester) async {
      await tester.pumpWidget(const _IntegrationFlowApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('open_register_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('register_name_field')),
        'Demo Merchant',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_email_field')),
        'merchant@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('register_password_field')),
        'secret123',
      );
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is RadioListTile && widget.value == 'merchant',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('register_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('Registered: merchant@example.com as merchant'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('login_email_field')),
        'merchant@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login_password_field')),
        'secret123',
      );
      await tester.tap(find.byKey(const ValueKey('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Logged in as: merchant@example.com'), findsOneWidget);
      expect(find.text('Role: merchant'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('open_new_product_button')));
      await tester.pumpAndSettle();

      expect(find.byType(NewProductScreen), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('new_product_name_field')),
        'Bagel box',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new_product_original_price_field')),
        '1000',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new_product_discounted_price_field')),
        '490',
      );
      await tester.enterText(
        find.byKey(const ValueKey('new_product_quantity_field')),
        '2',
      );
      final saveButton = find.byKey(const ValueKey('new_product_save_button'));
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Saved product: Bagel box'), findsOneWidget);
      expect(find.text('Category: Peksutemeny'), findsOneWidget);
      expect(find.text('Discounted price: 490 Ft'), findsOneWidget);
      expect(find.text('Quantity: 2'), findsOneWidget);
    },
  );
}

class _IntegrationFlowApp extends StatelessWidget {
  const _IntegrationFlowApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NearPick Integration Flow Harness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const _IntegrationFlowHarness(),
    );
  }
}

class _IntegrationFlowHarness extends StatefulWidget {
  const _IntegrationFlowHarness();

  @override
  State<_IntegrationFlowHarness> createState() =>
      _IntegrationFlowHarnessState();
}

class _IntegrationFlowHarnessState extends State<_IntegrationFlowHarness> {
  String? _registeredEmail;
  String? _registeredPassword;
  String? _registeredRole;
  String? _loggedInEmail;
  NewProductCommand? _savedProduct;

  Future<void> _register(
    String email,
    String password,
    String displayName,
    String role,
    String companyName,
  ) async {
    if (displayName.isEmpty) {
      throw StateError('display-name-required');
    }
    if (role == 'merchant' && companyName.trim().isEmpty) {
      throw StateError('company-name-required');
    }

    setState(() {
      _registeredEmail = email;
      _registeredPassword = password;
      _registeredRole = role;
    });
  }

  Future<void> _login(String email, String password) async {
    if (_registeredEmail != email || _registeredPassword != password) {
      throw StateError('invalid-credentials');
    }

    setState(() {
      _loggedInEmail = email;
    });
  }

  Future<void> _saveProduct(NewProductCommand command) async {
    setState(() {
      _savedProduct = command;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedInEmail == null) {
      return Stack(
        children: [
          LoginScreen(
            onLogin: _login,
            registerScreenBuilder: (_) => RegisterScreen(onRegister: _register),
          ),
          if (_registeredEmail != null && _registeredRole != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Registered: $_registeredEmail as $_registeredRole',
                  ),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Integration Flow Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Logged in as: $_loggedInEmail'),
            Text('Role: ${_registeredRole ?? 'unknown'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const ValueKey('open_new_product_button'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewProductScreen(
                      initialExpiry: DateTime(2026, 3, 20),
                      onSaveProduct: _saveProduct,
                    ),
                  ),
                );
              },
              child: const Text('Open new product form'),
            ),
            const SizedBox(height: 16),
            if (_savedProduct != null) ...[
              Text('Saved product: ${_savedProduct!.name}'),
              Text('Category: ${_savedProduct!.category}'),
              Text('Discounted price: ${_savedProduct!.discountedPrice} Ft'),
              Text('Quantity: ${_savedProduct!.quantity}'),
            ],
          ],
        ),
      ),
    );
  }
}
