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

class TelaInicial extends StatefulWidget {
  const TelaInicial({super.key});

  @override
  State<TelaInicial> createState() => _TelaInicialState();
}

class _TelaInicialState extends State<TelaInicial> {
  Timer? _timer;
  Duration _duracao = Duration.zero;
  bool _servicoEmAndamento = false;

  void _alternarServico() {
    if (_servicoEmAndamento) {
      _timer?.cancel();

      setState(() {
        _servicoEmAndamento = false;
      });
      return;
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

  String _formatarDuracao(Duration duracao) {
    final horas = duracao.inHours.toString().padLeft(2, '0');
    final minutos = duracao.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = duracao.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$horas:$minutos:$segundos';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      _servicoEmAndamento
                          ? 'Serviço em andamento'
                          : 'Serviço pausado',
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
            const Spacer(),
            FilledButton.icon(
              onPressed: _alternarServico,
              icon: Icon(
                _servicoEmAndamento ? Icons.pause : Icons.play_arrow,
              ),
              label: Text(
                _servicoEmAndamento ? 'Pausar serviço' : 'Iniciar serviço',
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