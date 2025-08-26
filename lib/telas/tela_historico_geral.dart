// lib/telas/tela_historico_geral.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum FiltroHistorico { todos, entradas, saidas }

class TelaHistoricoGeral extends StatefulWidget {
  const TelaHistoricoGeral({super.key});
  @override
  State<TelaHistoricoGeral> createState() => _TelaHistoricoGeralState();
}

class _TelaHistoricoGeralState extends State<TelaHistoricoGeral> {
  FiltroHistorico _filtroSelecionado = FiltroHistorico.todos;

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) =>
          Dialog(child: InteractiveViewer(child: Image.network(fotoUrl))),
    );
  }

  Query _construirConsulta() {
    Query consulta = FirebaseFirestore.instance.collection('movimentacoes');

    if (_filtroSelecionado == FiltroHistorico.entradas) {
      consulta = consulta.where('tipo', isEqualTo: 'Entrada');
    } else if (_filtroSelecionado == FiltroHistorico.saidas) {
      consulta = consulta.where('tipo', isEqualTo: 'Saída');
    }

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
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<FiltroHistorico>(
              segments: const <ButtonSegment<FiltroHistorico>>[
                ButtonSegment(
                  value: FiltroHistorico.todos,
                  label: Text('Todos'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: FiltroHistorico.entradas,
                  label: Text('Entradas'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
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

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final dados =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;

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
                    final Timestamp? timestamp =
                        dados['timestamp'] as Timestamp?;
                    final String dataFormatada = timestamp != null
                        ? DateFormat(
                            'dd/MM/yyyy HH:mm',
                            'pt_BR',
                          ).format(timestamp.toDate())
                        : 'Data indisponível';

                    // CORREÇÃO: Lógica robusta para lidar com ambos os formatos de localização
                    String localizacaoTexto = 'Local não informado';
                    if (dados.containsKey('localizacao')) {
                      if (dados['localizacao'] is String) {
                        localizacaoTexto = dados['localizacao'];
                      } else if (dados['localizacao'] is GeoPoint) {
                        final geoPoint = dados['localizacao'] as GeoPoint;
                        localizacaoTexto =
                            'Lat: ${geoPoint.latitude.toStringAsFixed(4)}, Lon: ${geoPoint.longitude.toStringAsFixed(4)}';
                      }
                    }

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
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
                            Text('Local: $localizacaoTexto'),
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
