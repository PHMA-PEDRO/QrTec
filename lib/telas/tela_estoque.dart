// lib/telas/tela_estoque.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 1. Transformamos em StatefulWidget
class TelaEstoque extends StatefulWidget {
  final String projectId;
  const TelaEstoque({super.key, required this.projectId});

  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque> {
  // 2. Variável para guardar o texto da busca
  String _termoBusca = '';
  final Set<String> _selecionados = {};
  bool _somenteProntos = false;
  bool _atualizando = false;

  Future<void> _marcarProntoParaEnvio() async {
    if (_selecionados.isEmpty || _atualizando) return;
    setState(() => _atualizando = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final tag in _selecionados) {
        final ref = FirebaseFirestore.instance
            .collection('estoque_atual')
            .doc(tag);
        batch.update(ref, {
          'prontoParaEnvio': true,
          'prontoParaEnvioTimestamp': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Marcado(s) ${_selecionados.length} equip. como Pronto para Envio.',
            ),
          ),
        );
        setState(() => _selecionados.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao atualizar: $e')));
      }
    } finally {
      if (mounted) setState(() => _atualizando = false);
    }
  }

  Future<void> _removerProntoParaEnvio(String tag) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Pronto para Envio?'),
        content: Text(
          'Tem certeza que deseja remover a liberação da TAG "$tag"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await FirebaseFirestore.instance
            .collection('estoque_atual')
            .doc(tag)
            .update({
              'prontoParaEnvio': false,
              'prontoParaEnvioTimestamp': null,
            });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Liberação removida para $tag.')),
        );
        setState(() {
          _selecionados.remove(tag);
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao remover: $e')));
        }
      }
    }
  }

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma foto disponível para este item.'),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            fotoUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estoque do Projeto'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: _somenteProntos ? 'Mostrar todos' : 'Ver liberados',
            icon: Icon(
              _somenteProntos
                  ? Icons.done_all
                  : Icons.playlist_add_check_circle_outlined,
            ),
            onPressed: () => setState(() => _somenteProntos = !_somenteProntos),
          ),
        ],
      ),
      body: Column(
        children: [
          // 3. Adicionamos a Barra de Busca
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por TAG',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _termoBusca = value
                      .toLowerCase(); // Guarda o termo em minúsculas
                });
              },
            ),
          ),

          // 4. A lista de resultados agora está dentro de um Expanded
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: (() {
                Query query = FirebaseFirestore.instance
                    .collection('estoque_atual')
                    .where('projetoId', isEqualTo: widget.projectId)
                    .where('status', isEqualTo: 'Em Estoque');
                if (_somenteProntos) {
                  query = query.where('prontoParaEnvio', isEqualTo: true);
                }
                return query.orderBy('timestamp', descending: true).snapshots();
              })(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o estoque.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum equipamento em estoque neste projeto.'),
                  );
                }

                // 5. Lógica de Filtragem
                final todosOsItens = snapshot.data!.docs;
                final itensFiltrados = _termoBusca.isEmpty
                    ? todosOsItens // Se a busca estiver vazia, mostra tudo
                    : todosOsItens.where((doc) {
                        final dados = doc.data() as Map<String, dynamic>;
                        final tag = (dados['tag'] as String? ?? '')
                            .toLowerCase();
                        return tag.contains(_termoBusca);
                      }).toList(); // Senão, filtra a lista

                if (itensFiltrados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum item encontrado com este termo.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: itensFiltrados.length,
                  itemBuilder: (context, index) {
                    final dados =
                        itensFiltrados[index].data() as Map<String, dynamic>;
                    final timestamp = dados['timestamp'] as Timestamp?;
                    final String dataFormatada = timestamp != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(timestamp.toDate())
                        : 'Data indisponível';
                    String diasNoStatus = '';
                    if (timestamp != null) {
                      final agora = DateTime.now();
                      final data = timestamp.toDate();
                      final diffDias = agora.difference(data).inDays;
                      diasNoStatus = diffDias <= 0
                          ? 'Hoje'
                          : diffDias == 1
                          ? '1 dia no status'
                          : '$diffDias dias no status';
                    }
                    final String? fotoUrl = dados['fotoUrl'];
                    final String localizacao =
                        dados['localizacao'] ?? 'Local não informado';
                    final String tag = dados['tag'] ?? '';
                    final bool pronto = (dados['prontoParaEnvio'] == true);

                    return Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 4,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _mostrarImagem(context, fotoUrl),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(right: 12.0, top: 2),
                                child: Icon(
                                  Icons.computer,
                                  size: 32,
                                  color: Colors.green,
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            tag.isEmpty
                                                ? 'TAG: N/A'
                                                : 'TAG: $tag',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (pronto)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'Pronto para Envio',
                                              style: TextStyle(
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            dados['responsavel'] ?? 'N/A',
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.place_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            localizacao,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.event_outlined,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          dataFormatada,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(width: 10),
                                        if (diasNoStatus.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              diasNoStatus,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.green,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (fotoUrl != null)
                                    const Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (pronto)
                                    IconButton(
                                      tooltip: 'Remover Pronto para Envio',
                                      icon: const Icon(
                                        Icons.remove_done,
                                        color: Colors.indigo,
                                      ),
                                      onPressed: () =>
                                          _removerProntoParaEnvio(tag),
                                    ),
                                  Checkbox(
                                    value: _selecionados.contains(tag),
                                    onChanged: tag.isEmpty
                                        ? null
                                        : (v) {
                                            setState(() {
                                              if (v == true) {
                                                _selecionados.add(tag);
                                              } else {
                                                _selecionados.remove(tag);
                                              }
                                            });
                                          },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          if (_selecionados.isNotEmpty)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.local_shipping_outlined),
                    label: Text(
                      _atualizando
                          ? 'Atualizando...'
                          : 'Marcar como Pronto para Envio (${_selecionados.length})',
                    ),
                    onPressed: _atualizando ? null : _marcarProntoParaEnvio,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
