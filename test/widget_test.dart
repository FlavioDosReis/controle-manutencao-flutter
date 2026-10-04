import 'package:controle_tempo_carro/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('inicia, pausa e finaliza um serviço', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(ControleTempoCarroApp(preferences: preferences));

    expect(find.text('Nenhuma manutenção em andamento.'), findsOneWidget);
    await tester.tap(find.text('Nova manutenção'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ABC1D23');
    await tester.enterText(find.byType(TextField).at(1), 'Troca de óleo');
    await tester.tap(find.text('Iniciar manutenção'));
    await tester.pump();
    expect(find.text('EM ANDAMENTO'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Pausar serviço'));
    await tester.pump();
    expect(find.text('PAUSADA'), findsOneWidget);

    await tester.tap(find.text('Finalizar manutenção'));
    await tester.pump();
    await tester.tap(find.text('Finalizar'));
    await tester.pump();
    expect(find.text('ABC1D23'), findsOneWidget);
    expect(find.textContaining('Troca de óleo'), findsOneWidget);
  });

  test('converte serviço finalizado para armazenamento local', () {
    final servico = ServicoFinalizado(
      veiculo: 'ABC1D23',
      descricao: 'Troca de óleo',
      duracao: const Duration(minutes: 30),
      finalizadoEm: DateTime(2026, 10, 4, 10),
    );

    expect(ServicoFinalizado.fromJson(servico.toJson()).descricao, 'Troca de óleo');
  });
}
