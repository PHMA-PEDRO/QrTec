import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TelaCadastroEquipamento extends StatefulWidget {
  const TelaCadastroEquipamento({super.key});

  @override
  State<TelaCadastroEquipamento> createState() =>
      _TelaCadastroEquipamentoState();
}

class _TelaCadastroEquipamentoState extends State<TelaCadastroEquipamento> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  bool _isLoading = false;

  void _mostrarQrCode(String tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code Gerado'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(data: tag, version: QrVersions.auto, size: 200.0),
        ),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _salvarEquipamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final String tag = _tagController.text.trim().toUpperCase();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('equipamentos')
          .doc(tag);
      final doc = await docRef.get();

      if (doc.exists) {
        throw Exception('Um equipamento com esta TAG já foi cadastrado.');
      }

      await docRef.set({
        'tag': tag,
        'nome': _nomeController.text.trim(),
        'descricao': _descricaoController.text.trim(),
        'dataCadastro': Timestamp.now(),
        'fotos': [],
      });

      if (mounted) {
        _mostrarQrCode(tag);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao salvar: ${e.toString().replaceAll("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Novo Equipamento'),
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
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'TAG do Equipamento (ID Único)',
                  border: OutlineInputBorder(),
                  hintText: 'EX: NOTE-001',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'A TAG é obrigatória.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Equipamento',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Notebook Dell Vostro',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'O nome é obrigatório.'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: i7, 16GB RAM, SN: 123XYZ',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _salvarEquipamento,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Salvar e Gerar QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
