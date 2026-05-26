import 'package:flutter_test/flutter_test.dart';
import 'package:kenko_shop/data/sample_products.dart';
import 'package:kenko_shop/main.dart' as app;

void main() {
  testWidgets('Kenko app renders fresh feed', (tester) async {
    await app.main();
    await tester.pump();
    await tester.pump();

    expect(find.text(sampleProducts.first.name), findsOneWidget);
  });
}
