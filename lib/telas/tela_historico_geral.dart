import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Enum para representar os estados do filtro de forma organizada
enum FiltroHistorico { todos, entradas, saidas }

class TelaHistoricoGeral extends StatefulWidget {
  const TelaHistoricoGeral({super.key});
  @override
  State<TelaHistoricoGeral> createState() => _TelaHistoricoGeralState();
}

class _TelaHistoricoGeralState extends State<TelaHistoricoGeral> {
  // O estado do filtro começa como "todos" por padrão
  FiltroHistorico _filtroSelecionado = FiltroHistorico.todos;
  // Variáveis para guardar as datas do filtro
  DateTime? _dataInicial;
  DateTime? _dataFinal;

  void _mostrarImagem(BuildContext context, String? fotoUrl) {
    if (fotoUrl == null || fotoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma foto disponível para esta movimentação.'),
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

  // Função que constrói a consulta ao Firestore baseada nos filtros
  Query _construirConsulta() {
    Query consulta = FirebaseFirestore.instance.collection('movimentacoes');

    // Aplica o filtro de tipo (Entrada/Saída)
    if (_filtroSelecionado == FiltroHistorico.entradas) {
      consulta = consulta.where('tipo', isEqualTo: 'Entrada');
    } else if (_filtroSelecionado == FiltroHistorico.saidas) {
      consulta = consulta.where('tipo', isEqualTo: 'Saída');
    }

    // Aplica o filtro de data inicial, se houver
    if (_dataInicial != null) {
      consulta = consulta.where(
        'timestamp',
        isGreaterThanOrEqualTo: _dataInicial,
      );
    }
    // Aplica o filtro de data final, se houver
    if (_dataFinal != null) {
      // Adicionamos 1 dia e subtraímos um milissegundo para incluir todos os horários do dia final
      DateTime dataFinalAjustada = DateTime(
        _dataFinal!.year,
        _dataFinal!.month,
        _dataFinal!.day,
        23,
        59,
        59,
      );
      consulta = consulta.where(
        'timestamp',
        isLessThanOrEqualTo: dataFinalAjustada,
      );
    }

    // Sempre ordena pela data mais recente
    return consulta.orderBy('timestamp', descending: true);
  }

  // Função para mostrar o seletor de data
  Future<void> _selecionarData(BuildContext context, bool isDataInicial) async {
    final DateTime? dataSelecionada = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('pt', 'BR'), // Para o calendário em português
    );

    if (dataSelecionada != null) {
      setState(() {
        if (isDataInicial) {
          _dataInicial = dataSelecionada;
        } else {
          _dataFinal = dataSelecionada;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatadorData = DateFormat('dd/MM/yy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico Geral'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barra de filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SegmentedButton<FiltroHistorico>(
                  segments: const <ButtonSegment<FiltroHistorico>>[
                    ButtonSegment(
                      value: FiltroHistorico.todos,
                      label: Text('Todos'),
                      icon: Icon(Icons.list_alt_outlined),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _dataInicial == null
                            ? 'Data Inicial'
                            : formatadorData.format(_dataInicial!),
                      ),
                      onPressed: () => _selecionarData(context, true),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _dataFinal == null
                            ? 'Data Final'
                            : formatadorData.format(_dataFinal!),
                      ),
                      onPressed: () => _selecionarData(context, false),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      tooltip: 'Limpar filtros de data',
                      onPressed: () {
                        setState(() {
                          _dataInicial = null;
                          _dataFinal = null;
                        });
                      },
                    ),
                  ],
                ),
              ],
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
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Ocorreu um erro. Verifique se os índices do Firestore foram criados para esta consulta.',
                        textAlign: TextAlign.center,
                      ),
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
                    final dados =
                        movimentacoes[index].data() as Map<String, dynamic>;

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
                        title: Text(
                          'TAG: ${dados['tagEquipamento'] ?? 'N/A'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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
