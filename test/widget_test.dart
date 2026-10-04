import 'package:controle_tempo_carro/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('inicia, pausa e finaliza um serviço', (tester) async {
    await tester.pumpWidget(const ControleTempoCarroApp());

    expect(find.text('Nenhum serviço em andamento'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'ABC1D23');
    await tester.enterText(find.byType(TextField).at(1), 'Troca de óleo');
    await tester.tap(find.text('Iniciar serviço'));
    await tester.pump();
    expect(find.text('Serviço em andamento'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Pausar serviço'));
    await tester.pump();
    expect(find.text('Serviço pausado'), findsOneWidget);

    await tester.tap(find.text('Finalizar serviço'));
    await tester.pump();
    expect(find.text('Nenhum serviço em andamento'), findsOneWidget);
    expect(find.text('ABC1D23'), findsOneWidget);
    expect(find.textContaining('Troca de óleo'), findsOneWidget);
  });
}
