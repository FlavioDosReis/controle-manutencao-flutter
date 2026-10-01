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

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Tempo'),
      ),
      body: const Center(
        child: Text('Seu controle de serviços começa aqui.'),
      ),
    );
  }
}