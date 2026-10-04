import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const ControleTempoCarroApp());
}

class ControleTempoCarroApp extends StatelessWidget {
  const ControleTempoCarroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Tempo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
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
}

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Timer? _timer;
  Duration _duracao = Duration.zero;
  bool _servicoEmAndamento = false;
  String? _veiculoServico;
  String? _descricaoServico;
  final _veiculoController = TextEditingController();
  final _descricaoController = TextEditingController();
  final List<ServicoFinalizado> _servicosFinalizados = [];

  void _alternarServico() {
    if (_servicoEmAndamento) {
      _timer?.cancel();

      setState(() {
        _servicoEmAndamento = false;
      });
      return;
    }

    if (_duracao == Duration.zero) {
      final veiculo = _veiculoController.text.trim();
      final descricao = _descricaoController.text.trim();
      if (veiculo.isEmpty || descricao.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Informe o veículo e o serviço antes de iniciar.')),
        );
        return;
      }
      _veiculoServico = veiculo;
      _descricaoServico = descricao;
    }

    setState(() {
      _servicoEmAndamento = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duracao += const Duration(seconds: 1);
      });
    });
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Serviço finalizado em ${_formatarDuracao(servico.duracao)}.',
        ),
      ),
    );
  }

  String _formatarDuracao(Duration duracao) {
    final horas = duracao.inHours.toString().padLeft(2, '0');
    final minutos = duracao.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracao.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$horas:$minutos:$segundos';
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes às $hora:$minuto';
  }

  String _mensagemStatus() {
    if (_servicoEmAndamento) {
      return 'Serviço em andamento';
    }

    if (_duracao == Duration.zero) {
      return 'Nenhum serviço em andamento';
    }

    return 'Serviço pausado';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _veiculoController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final possuiServico = _duracao > Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Tempo'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _veiculoController,
              enabled: !_servicoEmAndamento && _duracao == Duration.zero,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Veículo ou placa',
                hintText: 'Ex.: HB20 • ABC1D23',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descricaoController,
              enabled: !_servicoEmAndamento && _duracao == Duration.zero,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Serviço',
                hintText: 'Ex.: troca de óleo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Serviço atual',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 48,
                      color: _servicoEmAndamento ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mensagemStatus(),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _formatarDuracao(_duracao),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Últimos serviços',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _servicosFinalizados.isEmpty
                  ? const Center(
                      child: Text('Nenhum serviço finalizado ainda.'),
                    )
                  : ListView.separated(
                      itemCount: _servicosFinalizados.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final servico = _servicosFinalizados[index];

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle_outline),
                            title: Text(servico.veiculo),
                            subtitle: Text(
                              '${servico.descricao} • ${_formatarDuracao(servico.duracao)}\nFinalizado em ${_formatarData(servico.finalizadoEm)}',
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
            ),
            if (possuiServico) ...[
              OutlinedButton.icon(
                onPressed: _finalizarServico,
                icon: const Icon(Icons.check),
                label: const Text('Finalizar serviço'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              onPressed: _alternarServico,
              icon: Icon(
                _servicoEmAndamento ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(
                _servicoEmAndamento
                    ? 'Pausar serviço'
                    : possuiServico
                        ? 'Continuar serviço'
                        : 'Iniciar serviço',
              ),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
