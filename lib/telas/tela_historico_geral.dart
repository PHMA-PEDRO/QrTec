// lib/telas/tela_historico_geral.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum para representar os estados do filtro
enum FiltroHistorico { todos, entradas, saidas }

class TelaHistoricoGeral extends StatefulWidget {
  const TelaHistoricoGeral({super.key});

  @override
  State<TelaHistoricoGeral> createState() => _TelaHistoricoGeralState();
}

class _TelaHistoricoGeralState extends State<TelaHistoricoGeral> {
  // O estado do filtro começa como "todos"
  FiltroHistorico _filtroSelecionado = FiltroHistorico.todos;

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: InteractiveViewer(child: Image.network(fotoUrl)),
      ),
    );
  }

  // Função que constrói a consulta ao Firestore baseada no filtro
  Query _construirConsulta() {
    Query consulta = FirebaseFirestore.instance.collection('movimentacoes');

    // Aplica o filtro se não for "todos"
    if (_filtroSelecionado == FiltroHistorico.entradas) {
      consulta = consulta.where('tipo', isEqualTo: 'Entrada');
    } else if (_filtroSelecionado == FiltroHistorico.saidas) {
      consulta = consulta.where('tipo', isEqualTo: 'Saída');
    }

    // Sempre ordena pela data mais recente
    return consulta.orderBy('timestamp', descending: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Geral'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de filtro
          Container(
            color: Colors.grey.shade200,
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: SegmentedButton<FiltroHistorico>(
              segments: const <ButtonSegment<FiltroHistorico>>[
                ButtonSegment<FiltroHistorico>(
                  value: FiltroHistorico.todos,
                  label: Text('Todos'),
                  icon: Icon(Icons.list_alt),
                ),
                ButtonSegment<FiltroHistorico>(
                  value: FiltroHistorico.entradas,
                  label: Text('Entradas'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<FiltroHistorico>(
                  value: FiltroHistorico.saidas,
                  label: Text('Saídas'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_filtroSelecionado},
              onSelectionChanged: (Set<FiltroHistorico> newSelection) {
                setState(() {
                  _filtroSelecionado = newSelection.first;
                });
              },
            ),
          ),

          // A lista agora ocupa o resto da tela
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _construirConsulta().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Ocorreu um erro. Verifique os índices do Firestore.',
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nenhuma movimentação encontrada para este filtro.',
                    ),
                  );
                }

                final movimentacoes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: movimentacoes.length,
                  itemBuilder: (context, index) {
                    final doc = movimentacoes[index];
                    final dados = doc.data() as Map<String, dynamic>;

                    final bool isEntrada = dados['tipo'] == 'Entrada';
                    final String statusTexto = isEntrada
                        ? 'Em Estoque'
                        : 'Em Transporte';
                    final Color statusCor = isEntrada
                        ? Colors.green
                        : Colors.orange.shade700;
                    final IconData iconeMovimento = isEntrada
                        ? Icons.arrow_downward
                        : Icons.arrow_upward;
                    final String? fotoUrl = dados['fotoUrl'];
                    final timestamp = dados['timestamp'] as Timestamp?;
                    final String dataFormatada = timestamp != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(timestamp.toDate())
                        : 'Data indisponível';

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: statusCor,
                          child: Icon(iconeMovimento, color: Colors.white),
                        ),
                        title: Text('TAG: ${dados['tagEquipamento'] ?? 'N/A'}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: $statusTexto',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: statusCor,
                              ),
                            ),
                            Text('Projeto: ${dados['nomeProjeto'] ?? 'N/A'}'),
                            Text(
                              'Responsável: ${dados['responsavel'] ?? 'N/A'}',
                            ),
                            Text('Data: $dataFormatada'),
                          ],
                        ),
                        trailing: fotoUrl != null
                            ? const Icon(Icons.camera_alt)
                            : null,
                        onTap: () => _mostrarImagem(context, fotoUrl),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
