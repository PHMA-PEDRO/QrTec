import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TelaAprovarEnvio extends StatefulWidget {
  const TelaAprovarEnvio({super.key});

  @override
  State<TelaAprovarEnvio> createState() => _TelaAprovarEnvioState();
}

class _TelaAprovarEnvioState extends State<TelaAprovarEnvio> {
  String _filtroTipo = 'TODOS';

  Stream<QuerySnapshot> _streamLiberados() {
    return FirebaseFirestore.instance
        .collection('estoque_atual')
        .where('status', isEqualTo: 'Em Estoque')
        .where('prontoParaEnvio', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Tela somente leitura com filtro por tipo

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipamentos Aguardando Envio'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                const Text('Tipo: '),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filtroTipo,
                  items: const [
                    DropdownMenuItem(value: 'TODOS', child: Text('Todos')),
                    DropdownMenuItem(value: 'PADRÃO', child: Text('PADRÃO')),
                    DropdownMenuItem(
                      value: 'TI UTILITARIO',
                      child: Text('TI UTILITARIO'),
                    ),
                    DropdownMenuItem(value: 'LOCAÇÃO', child: Text('LOCAÇÃO')),
                  ],
                  onChanged: (v) => setState(() => _filtroTipo = v ?? 'TODOS'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _streamLiberados(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar itens liberados.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum equipamento liberado no momento.'),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final docs = _filtroTipo == 'TODOS'
                    ? allDocs
                    : allDocs.where((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final tipo =
                            (m['tipoEquipamento'] as String?) ?? 'PADRÃO';
                        return tipo == _filtroTipo;
                      }).toList();

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum item para o filtro selecionado.'),
                  );
                }

                final df = DateFormat('dd/MM/yyyy HH:mm');
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final m = doc.data() as Map<String, dynamic>;
                    final tag = (m['tag'] as String?) ?? doc.id;
                    final nomeProjeto = (m['nomeProjeto'] as String?) ?? '';
                    final tipoEquip =
                        (m['tipoEquipamento'] as String?) ?? 'PADRÃO';
                    final ts = m['timestamp'] as Timestamp?;
                    final dataTxt = ts != null
                        ? df.format(ts.toDate())
                        : 'Data indisp.';

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.inventory_2,
                          color: Colors.indigo,
                        ),
                        title: Text(
                          'TAG: $tag',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (nomeProjeto.isNotEmpty)
                              Text('Projeto: $nomeProjeto'),
                            Text('Tipo: $tipoEquip'),
                            Text('Liberado em: $dataTxt'),
                          ],
                        ),
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
