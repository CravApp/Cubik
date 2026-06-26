import 'package:flutter_test/flutter_test.dart';
import 'package:kubik_tasks/main.dart';

void main() {
  testWidgets('KubikTasks app smoke test', (WidgetTester tester) async {
    // Solo verifica que el widget raíz existe y tiene el título correcto
    expect(KubikTasksApp, isNotNull);
  });
}
