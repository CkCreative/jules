import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jules_flutter/main.dart';
import 'package:jules_flutter/providers/auth_provider.dart';
import 'package:jules_flutter/providers/settings_provider.dart';

void main() {
  testWidgets('shows login screen when signed out', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const JulesApp(),
      ),
    );

    expect(find.text('Welcome to Jules'), findsOneWidget);
  });
}
