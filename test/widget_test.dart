import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reednote/main.dart';

void main() {
  testWidgets('ReedNoteApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ReedNoteApp());
    await tester.pumpAndSettle();

    expect(find.text('ReedNote - リード管理・調整 (レベル別)'), findsNothing);
    expect(find.text('1. リード管理・調整'), findsOneWidget);
    expect(find.text('2. 素材ストック管理'), findsOneWidget);
  });
}
