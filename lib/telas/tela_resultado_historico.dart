import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class TelaResultadoHistorico extends StatelessWidget {
  final String tagEquipamento;
  const TelaResultadoHistorico({super.key, required this.tagEquipamento});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico: $tagEquipamento'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('movimentacoes')
            .where('tagEquipamento', isEqualTo: tagEquipamento)
            .orderBy('timestamp', descending: true)
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
              message:
                  'Não foi possível carregar o histórico. Verifique os índices do Firestore.',
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.search_off,
              title: 'Nenhum Histórico Encontrado',
              message:
                  'Não há movimentações registradas para a TAG: $tagEquipamento',
            );
          }

          final movimentacoes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: movimentacoes.length,
            itemBuilder: (context, index) {
              final dados = movimentacoes[index].data() as Map<String, dynamic>;
              final bool isEntrada = dados['tipo'] == 'Entrada';
              final Color corMovimento = isEntrada
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
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: corMovimento,
                    child: Icon(iconeMovimento, color: Colors.white),
                  ),
                  title: Text(
                    '${dados['tipo']} em $dataFormatada',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Projeto: ${dados['nomeProjeto'] ?? 'N/A'}'),
                      Text('Responsável: ${dados['responsavel'] ?? 'N/A'}'),
                      Text('Local: $localizacaoTexto'),
                    ],
                  ),
                  trailing: fotoUrl != null
                      ? const Icon(Icons.camera_alt, color: Colors.grey)
                      : null,
                  onTap: () => _mostrarImagem(context, fotoUrl),
                ),
              );
            },
          );
        },
      ),
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
              const SizedBox(height: 4),
              Container(height: 12, width: 180, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
