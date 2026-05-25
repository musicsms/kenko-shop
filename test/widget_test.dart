import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/main.dart' as app;

void main() {
  testWidgets('Kenko app renders shell', (tester) async {
    app.main();
    await tester.pump();

    expect(find.text('Kenko Fresh'), findsOneWidget);
  });
}
