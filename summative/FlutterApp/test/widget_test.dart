import 'package:flutter_test/flutter_test.dart';

import 'package:breach_estimator/main.dart';

void main() {
  testWidgets('shows 12 inputs, a Predict button and a missing-value error', (tester) async {
    await tester.pumpWidget(const BreachEstimatorApp());

    expect(find.text('Predict'), findsOneWidget);
    expect(inputs.length, 12);

    await tester.ensureVisible(find.text('Predict'));
    await tester.tap(find.text('Predict'));
    await tester.pump();

    expect(find.text('Please fix the following:'), findsOneWidget);
  });
}
