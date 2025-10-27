import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';

class TelaGerenciamentoEquipamentos extends StatelessWidget {
  const TelaGerenciamentoEquipamentos({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Equipamentos'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add), text: 'Cadastrar Novo'),
              Tab(icon: Icon(Icons.list), text: 'Gerenciar Existentes'),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: const TabBarView(
          children: [AbaCadastrarNovo(), AbaGerenciarExistentes()],
        ),
      ),
    );
  }
}

// ABA 1: CADASTRAR NOVO EQUIPAMENTO
class AbaCadastrarNovo extends StatefulWidget {
  const AbaCadastrarNovo({super.key});
  @override
  State<AbaCadastrarNovo> createState() => _AbaCadastrarNovoState();
}

class _AbaCadastrarNovoState extends State<AbaCadastrarNovo> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  String _tipoEquipamento = 'PADRÃO'; // Valor padrão
  bool _isLoading = false;

  // Lista de tipos de equipamento disponíveis
  final List<String> _tiposEquipamento = ['PADRÃO', 'LOCAÇÃO', 'TI UTILITARIO'];

  Future<void> _gerarECompartilharPdf(
    String tag,
    String nome,
    String descricao,
    String tipoEquipamento,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Etiqueta de Identificação de Equipamento',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: tag,
                  width: 200,
                  height: 200,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  tag,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(nome, style: pw.TextStyle(fontSize: 18)),
                pw.Text(
                  'Tipo: $tipoEquipamento',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  descricao,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/etiqueta_qr_$tag.pdf");
    await file.writeAsBytes(await pdf.save());
    final xfile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: 'Etiqueta para o equipamento $tag'),
    );
  }

  void _mostrarDialogSucesso(
    String tag,
    String nome,
    String descricao,
    String tipoEquipamento,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Equipamento Salvo!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('O QR Code abaixo foi gerado para a TAG:'),
            const SizedBox(height: 16),
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: tag, version: QrVersions.auto),
            ),
            const SizedBox(height: 16),
            Text(
              tag,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tipo: $tipoEquipamento',
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Fechar'),
            onPressed: () {
              Navigator.of(context).pop();
              _tagController.clear();
              _nomeController.clear();
              _descricaoController.clear();
              setState(() {
                _tipoEquipamento = 'PADRÃO'; // Reset para valor padrão
              });
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar PDF'),
            onPressed: () =>
                _gerarECompartilharPdf(tag, nome, descricao, tipoEquipamento),
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
    final String nome = _nomeController.text.trim();
    final String descricao = _descricaoController.text.trim();
    final String tipoEquipamento = _tipoEquipamento;

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
        'nome': nome,
        'descricao': descricao,
        'tipo_equipamento': tipoEquipamento,
        'dataCadastro': Timestamp.now(),
        'fotos': [],
        'status_operacional': 'Ativo',
        'observacao_inativacao': '',
      });
      if (mounted) {
        _mostrarDialogSucesso(tag, nome, descricao, tipoEquipamento);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${e.toString().replaceAll("Exception: ", "")}',
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
    return SingleChildScrollView(
      child: Padding(
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
              DropdownButtonFormField<String>(
                value: _tipoEquipamento,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Equipamento',
                  border: OutlineInputBorder(),
                ),
                items: _tiposEquipamento.map((String tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo,
                    child: Text(tipo),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _tipoEquipamento = newValue!;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione o tipo de equipamento' : null,
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

// ABA 2: GERENCIAR EQUIPAMENTOS EXISTENTES
class AbaGerenciarExistentes extends StatefulWidget {
  const AbaGerenciarExistentes({super.key});
  @override
  State<AbaGerenciarExistentes> createState() => _AbaGerenciarExistentesState();
}

class _AbaGerenciarExistentesState extends State<AbaGerenciarExistentes> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _textoBusca = '';

  Future<void> _gerarECompartilharPdf(
    String tag,
    String nome,
    String descricao,
    String tipoEquipamento,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'Etiqueta de Identificação de Equipamento',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: tag,
                  width: 200,
                  height: 200,
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  tag,
                  style: pw.TextStyle(
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(nome, style: pw.TextStyle(fontSize: 18)),
                pw.Text(
                  'Tipo: $tipoEquipamento',
                  style: pw.TextStyle(fontSize: 14),
                ),
                pw.Text(
                  descricao,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/etiqueta_qr_$tag.pdf");
    await file.writeAsBytes(await pdf.save());
    final xfile = XFile(file.path);
    await SharePlus.instance.share(
      ShareParams(files: [xfile], text: 'Etiqueta para o equipamento $tag'),
    );
  }

  void _mostrarDialogEquipamento(Map<String, dynamic> dados) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(dados['tag']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(data: dados['tag'], version: QrVersions.auto),
            ),
            const SizedBox(height: 16),
            Text(
              'Tipo: ${dados['tipo_equipamento'] ?? 'PADRÃO'}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar PDF'),
            onPressed: () => _gerarECompartilharPdf(
              dados['tag'],
              dados['nome'],
              dados['descricao'],
              dados['tipo_equipamento'] ?? 'PADRÃO',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogInativar(String tag) async {
    final observacaoController = TextEditingController();
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Inativar Equipamento: $tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite uma observação para a inativação (ex: "Tela quebrada", "Em manutenção").',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: observacaoController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Observação',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Confirmar Inativação',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      if (observacaoController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('A observação é obrigatória para inativar.'),
          ),
        );
        return;
      }
      await _inativarEquipamento(tag, observacaoController.text.trim());
    }
  }

  Future<void> _inativarEquipamento(String tag, String observacao) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final equipRef = _firestore.collection('equipamentos').doc(tag);
        transaction.update(equipRef, {
          'status_operacional': 'Inativo',
          'observacao_inativacao': observacao,
        });
        final estoqueRef = _firestore.collection('estoque_atual').doc(tag);
        transaction.delete(estoqueRef);
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Equipamento $tag inativado.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao inativar: $e')));
      }
    }
  }

  Future<void> _reativarEquipamento(String tag) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Ação'),
        content: const Text('Deseja reativar este equipamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reativar',
              style: TextStyle(color: Colors.green),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    try {
      await _firestore.collection('equipamentos').doc(tag).update({
        'status_operacional': 'Ativo',
        'observacao_inativacao': '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Equipamento $tag reativado com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao reativar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              labelText: 'Buscar por TAG ou Nome...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _textoBusca = value;
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('equipamentos')
                .orderBy('tag')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: 6,
                  itemBuilder: (context, index) => const ListItemSkeleton(),
                );
              }
              if (snapshot.hasError) {
                return const EmptyStateWidget(
                  icon: Icons.error_outline,
                  title: 'Ocorreu um Erro',
                  message: 'Não foi possível carregar os equipamentos.',
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.computer_outlined,
                  title: 'Nenhum Equipamento Cadastrado',
                  message:
                      'Use a aba "Cadastrar Novo" para adicionar o primeiro equipamento.',
                );
              }

              final todosEquipamentos = snapshot.data!.docs;
              final equipamentosFiltrados = todosEquipamentos.where((doc) {
                final dados = doc.data() as Map<String, dynamic>;
                final String tag = dados['tag']?.toLowerCase() ?? '';
                final String nome = dados['nome']?.toLowerCase() ?? '';
                final String busca = _textoBusca.toLowerCase();
                return tag.contains(busca) || nome.contains(busca);
              }).toList();

              if (equipamentosFiltrados.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.search_off,
                  title: 'Nenhum Equipamento Encontrado',
                  message: 'Tente um termo de busca diferente.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: equipamentosFiltrados.length,
                itemBuilder: (context, index) {
                  final doc = equipamentosFiltrados[index];
                  final dados = doc.data() as Map<String, dynamic>;
                  final String status = dados['status_operacional'] ?? 'Ativo';
                  final bool isAtivo = status == 'Ativo';

                  return Card(
                    color: isAtivo ? Colors.white : Colors.grey.shade300,
                    child: ListTile(
                      leading: Icon(
                        Icons.computer,
                        color: isAtivo ? Colors.indigo : Colors.grey,
                      ),
                      title: Text(dados['tag'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dados['nome'] ?? ''),
                          const SizedBox(height: 4),
                          Text(
                            'Tipo: ${dados['tipo_equipamento'] ?? 'PADRÃO'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(status),
                            backgroundColor: isAtivo
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                          ),
                          isAtivo
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.power_settings_new,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Inativar',
                                  onPressed: () =>
                                      _mostrarDialogInativar(dados['tag']),
                                )
                              : IconButton(
                                  icon: const Icon(
                                    Icons.power_settings_new,
                                    color: Colors.green,
                                  ),
                                  tooltip: 'Reativar',
                                  onPressed: () =>
                                      _reativarEquipamento(dados['tag']),
                                ),
                        ],
                      ),
                      onTap: () => _mostrarDialogEquipamento(dados),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Widgets reutilizáveis
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: ListTile(
          leading: const CircleAvatar(backgroundColor: Colors.white),
          title: Container(height: 16, width: 150, color: Colors.white),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Container(height: 12, width: 200, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
