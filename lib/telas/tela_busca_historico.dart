// lib/telas/tela_busca_historico.dart

import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_resultado_historico.dart';

class TelaBuscaHistorico extends StatefulWidget {
  const TelaBuscaHistorico({super.key});

  @override
  State<TelaBuscaHistorico> createState() => _TelaBuscaHistoricoState();
}

class _TelaBuscaHistoricoState extends State<TelaBuscaHistorico> {
  final _tagController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _buscarHistorico() {
    if (_formKey.currentState!.validate()) {
      final String tag = _tagController.text.trim().toUpperCase();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TelaResultadoHistorico(tagEquipamento: tag),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Histórico'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Digite a TAG do equipamento para ver todo o seu histórico de movimentações.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'TAG do Equipamento',
                  border: OutlineInputBorder(),
                  hintText: 'EX: NOTE-001',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira uma TAG.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _buscarHistorico,
              ),
            ],
          ),
        ),
      ),
    );
  }
}