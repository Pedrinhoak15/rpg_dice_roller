import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rpg_dice_roller/main.dart';

void main() {
  setUp(() {
    // Cria um armazenamento falso apenas para os testes.
    // Isso evita erro do shared_preferences durante o flutter test.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'aplicativo mostra o titulo e o botao de rolagem',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const RpgDiceApp(),
      );

      // Aguarda a leitura inicial do histórico.
      await tester.pumpAndSettle();

      expect(
        find.text('RPG Dice Roller'),
        findsOneWidget,
      );

      expect(
        find.text('ROLAR DADOS'),
        findsOneWidget,
      );

      expect(
        find.text('Configure e role os dados'),
        findsOneWidget,
      );

      expect(
        find.text('d20'),
        findsOneWidget,
      );

      expect(
        find.text('d6'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'aplicativo mostra os campos de configuracao',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const RpgDiceApp(),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Quantidade'),
        findsOneWidget,
      );

      expect(
        find.text('Modificador'),
        findsOneWidget,
      );

      expect(
        find.text('Histórico local'),
        findsOneWidget,
      );
    },
  );
}
