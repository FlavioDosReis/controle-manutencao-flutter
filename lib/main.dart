import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _blue = Color(0xFF1565C0);
const _darkBlue = Color(0xFF0D47A1);
const _orange = Color(0xFFFF7300);
const _background = Color(0xFFE5EAF1);
const _ink = Color(0xFF1F2937);
const _muted = Color(0xFF6B7280);
const _green = Color(0xFF16A344);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(ControleTempoCarroApp(preferences: preferences));
}

class ControleTempoCarroApp extends StatelessWidget {
  const ControleTempoCarroApp({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Carrão Auto Peças',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: _blue),
          scaffoldBackgroundColor: _background,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(backgroundColor: _background, foregroundColor: _ink),
        ),
        home: TelaInicial(preferences: preferences),
      );
}

class ServicoFinalizado {
  const ServicoFinalizado({
    required this.veiculo,
    required this.descricao,
    required this.duracao,
    required this.finalizadoEm,
  });

  final String veiculo;
  final String descricao;
  final Duration duracao;
  final DateTime finalizadoEm;

  Map<String, dynamic> toJson() => {
        'veiculo': veiculo,
        'descricao': descricao,
        'duracaoEmMilissegundos': duracao.inMilliseconds,
        'finalizadoEm': finalizadoEm.toIso8601String(),
      };

  factory ServicoFinalizado.fromJson(Map<String, dynamic> json) => ServicoFinalizado(
        veiculo: json['veiculo'] as String,
        descricao: json['descricao'] as String,
        duracao: Duration(milliseconds: json['duracaoEmMilissegundos'] as int),
        finalizadoEm: DateTime.parse(json['finalizadoEm'] as String),
      );
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key, required this.preferences});

  final SharedPreferences preferences;

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  static const _historicoKey = 'servicos_finalizados';
  Timer? _timer;
  Duration _duracao = Duration.zero;
  bool _servicoEmAndamento = false;
  String? _veiculoServico;
  String? _descricaoServico;
  int _pagina = 0;
  final _veiculoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final List<ServicoFinalizado> _servicosFinalizados = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final salvo = widget.preferences.getString(_historicoKey);
    if (salvo == null) return;
    final historico = (jsonDecode(salvo) as List)
        .map((item) => ServicoFinalizado.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    if (mounted) setState(() => _servicosFinalizados.addAll(historico));
  }

  Future<void> _salvarHistorico() async {
    await widget.preferences.setString(
      _historicoKey,
      jsonEncode(_servicosFinalizados.map((item) => item.toJson()).toList()),
    );
  }

  void _alternarServico() {
    if (_servicoEmAndamento) {
      _timer?.cancel();
      setState(() => _servicoEmAndamento = false);
      return;
    }
    if (_duracao == Duration.zero) {
      final veiculo = _veiculoController.text.trim();
      final descricao = _descricaoController.text.trim();
      if (veiculo.isEmpty || descricao.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o veículo e o serviço antes de iniciar.')));
        return;
      }
      _veiculoServico = veiculo;
      _descricaoServico = descricao;
    }
    setState(() => _servicoEmAndamento = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _duracao += const Duration(seconds: 1));
    });
  }

  void _confirmarFinalizacao() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar manutenção?'),
        content: const Text('O tempo total será salvo no histórico.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(onPressed: () { Navigator.pop(context); _finalizarServico(); }, child: const Text('Finalizar')),
        ],
      ),
    );
  }

  void _finalizarServico() {
    final servico = ServicoFinalizado(
      veiculo: _veiculoServico ?? 'Veículo não informado',
      descricao: _descricaoServico ?? 'Serviço sem descrição',
      duracao: _duracao,
      finalizadoEm: DateTime.now(),
    );
    _timer?.cancel();
    setState(() {
      _servicoEmAndamento = false;
      _duracao = Duration.zero;
      _veiculoServico = null;
      _descricaoServico = null;
      _veiculoController.clear();
      _descricaoController.clear();
      _servicosFinalizados.insert(0, servico);
      _pagina = 2;
    });
    unawaited(_salvarHistorico());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Manutenção finalizada em ${_formatarDuracao(servico.duracao)}.')));
  }

  String _formatarDuracao(Duration duracao) {
    final horas = duracao.inHours.toString().padLeft(2, '0');
    final minutos = duracao.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracao.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$horas:$minutos:$segundos';
  }

  String _formatarData(DateTime data) => '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';

  Duration get _tempoMedio => _servicosFinalizados.isEmpty
      ? Duration.zero
      : Duration(seconds: _servicosFinalizados.map((item) => item.duracao.inSeconds).reduce((a, b) => a + b) ~/ _servicosFinalizados.length);

  @override
  void dispose() {
    _timer?.cancel();
    _veiculoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulos = ['Manutenções', 'Nova manutenção', 'Histórico'];
    final paginas = [_dashboard(), _novaManutencao(), _historico()];
    return Scaffold(
      appBar: AppBar(title: Text(titulos[_pagina], style: const TextStyle(fontWeight: FontWeight.w700)), centerTitle: false),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: paginas[_pagina]))),
      floatingActionButton: _pagina == 0 ? FloatingActionButton(onPressed: () => setState(() => _pagina = 1), backgroundColor: _orange, foregroundColor: Colors.white, child: const Icon(Icons.add)) : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pagina,
        onDestinationSelected: (value) => setState(() => _pagina = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'Nova manutenção'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }

  Widget _dashboard() => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Olá!', style: TextStyle(color: _ink, fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Acompanhe as manutenções da oficina em tempo real.', style: TextStyle(color: _muted)),
        const SizedBox(height: 22),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.65, children: [
          _MetricCard(label: 'Em manutenção', value: _servicoEmAndamento ? '1' : '0', icon: Icons.build_outlined, color: _blue),
          _MetricCard(label: 'Finalizadas', value: '${_servicosFinalizados.length}', icon: Icons.check_circle_outline, color: _green),
          _MetricCard(label: 'Tempo médio', value: _formatarDuracao(_tempoMedio), icon: Icons.timer_outlined, color: _orange),
          _MetricCard(label: 'Total', value: '${_servicosFinalizados.length + (_duracao > Duration.zero ? 1 : 0)}', icon: Icons.bar_chart_outlined, color: _blue),
        ]),
        const SizedBox(height: 26),
        Row(children: [const Text('Manutenções em andamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ink)), const Spacer(), Text(_servicoEmAndamento ? '1 ativa' : 'Nenhuma', style: const TextStyle(color: _blue, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 12),
        if (_duracao == Duration.zero) _emptyCard('Nenhuma manutenção em andamento.', 'Abra uma nova manutenção para começar.') else _servicoAtualCard(),
      ]);

  Widget _novaManutencao() => ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Dados do serviço', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ink)),
        const SizedBox(height: 6),
        const Text('Informe os dados para iniciar o atendimento.', style: TextStyle(color: _muted)),
        const SizedBox(height: 24),
        TextField(controller: _veiculoController, enabled: _duracao == Duration.zero, textCapitalization: TextCapitalization.characters, decoration: _input('Placa ou veículo *', 'Ex.: ABC-1234')),
        const SizedBox(height: 16),
        TextField(controller: _descricaoController, enabled: _duracao == Duration.zero, textCapitalization: TextCapitalization.sentences, maxLines: 2, decoration: _input('Serviço realizado *', 'Ex.: troca de óleo e filtro')),
        const SizedBox(height: 24),
        if (_duracao > Duration.zero) _servicoAtualCard(),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _alternarServico, icon: Icon(_servicoEmAndamento ? Icons.pause : Icons.play_arrow), label: Text(_servicoEmAndamento ? 'Pausar serviço' : _duracao > Duration.zero ? 'Continuar serviço' : 'Iniciar manutenção'), style: FilledButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 17))),
        if (_duracao > Duration.zero) ...[const SizedBox(height: 12), OutlinedButton.icon(onPressed: _confirmarFinalizacao, icon: const Icon(Icons.check_circle_outline), label: const Text('Finalizar manutenção'), style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700, padding: const EdgeInsets.symmetric(vertical: 16)))],
      ]);

  Widget _historico() => _servicosFinalizados.isEmpty
      ? Center(child: _emptyCard('Nenhuma manutenção finalizada.', 'Os serviços concluídos aparecerão aqui.'))
      : ListView(padding: const EdgeInsets.all(20), children: [
          const Text('Histórico de manutenções', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ink)),
          const SizedBox(height: 4), Text('${_servicosFinalizados.length} atendimentos registrados', style: const TextStyle(color: _muted)), const SizedBox(height: 18),
          ..._servicosFinalizados.map((servico) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _historicoCard(servico))),
        ]);

  InputDecoration _input(String label, String hint) => InputDecoration(labelText: label, hintText: hint, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8F1FF))));

  Widget _servicoAtualCard() => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE8F1FF))), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Icon(Icons.directions_car_outlined, color: _blue), const SizedBox(width: 8), Expanded(child: Text(_veiculoServico ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: _ink))), _StatusChip(active: _servicoEmAndamento)]),
        const SizedBox(height: 8), Text(_descricaoServico ?? '', style: const TextStyle(color: _muted)), const SizedBox(height: 20),
        Center(child: Column(children: [const Text('TEMPO DECORRIDO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)), const SizedBox(height: 6), Text(_formatarDuracao(_duracao), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _ink))])),
      ])));

  Widget _historicoCard(ServicoFinalizado servico) => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: ListTile(leading: const CircleAvatar(backgroundColor: Color(0xFFE8F1FF), foregroundColor: _blue, child: Icon(Icons.directions_car_outlined)), title: Text(servico.veiculo, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text('${servico.descricao}\n${_formatarData(servico.finalizadoEm)}'), isThreeLine: true, trailing: Text(_formatarDuracao(servico.duracao), style: const TextStyle(color: _blue, fontWeight: FontWeight.bold))));

  Widget _emptyCard(String title, String description) => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(26), child: Column(children: [const Icon(Icons.build_circle_outlined, color: _blue, size: 42), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: _ink)), const SizedBox(height: 4), Text(description, textAlign: TextAlign.center, style: const TextStyle(color: _muted))])));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(color: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 19), const Spacer(), Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _ink)), Text(label, style: const TextStyle(fontSize: 11, color: _muted))])));
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: active ? const Color(0xFFE8F1FF) : const Color(0xFFFFF0E5), borderRadius: BorderRadius.circular(14)), child: Text(active ? 'EM ANDAMENTO' : 'PAUSADA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: active ? _blue : _orange)));
}
