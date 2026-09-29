import 'package:flutter_test/flutter_test.dart';
import 'package:safe_scan_qr/main.dart';
import 'package:safe_scan_qr/pages/opening_page.dart';

void main() {
  testWidgets('App opens on the welcome screen', (tester) async {
    await tester.pumpWidget(const SafeScanQrApp());
    expect(find.byType(OpeningPage), findsOneWidget);
  });
}
