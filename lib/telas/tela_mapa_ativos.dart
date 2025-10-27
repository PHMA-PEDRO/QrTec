// lib/telas/tela_mapa_ativos.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TelaMapaAtivos extends StatefulWidget {
  const TelaMapaAtivos({super.key});

  @override
  State<TelaMapaAtivos> createState() => _TelaMapaAtivosState();
}

class _TelaMapaAtivosState extends State<TelaMapaAtivos> {
  // Posição inicial do mapa (centrado em Recife)
  static const LatLng _posicaoInicial = LatLng(-8.047562, -34.877022);
  String _filtroTipo = 'TODOS';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização dos Ativos em Transporte'),
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
              // A consulta busca todos os itens com status "Em Transporte"
              stream: FirebaseFirestore.instance
                  .collection('estoque_atual')
                  .where('status', isEqualTo: 'Em Transporte')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Erro ao carregar dados.'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('Nenhum equipamento em transporte no momento.'),
                  );
                }

                // Cria um conjunto de marcadores para o mapa
                final Set<Marker> markers = {};
                final docs = snapshot.data!.docs;

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final GeoPoint? coordenadas =
                      data['coordenadas'] as GeoPoint?;
                  final String tipoEquip =
                      (data['tipoEquipamento'] as String?) ?? 'PADRÃO';
                  if (_filtroTipo != 'TODOS' && tipoEquip != _filtroTipo) {
                    continue;
                  }
                  if (coordenadas != null) {
                    final String tag = data['tag'] ?? 'N/A';
                    final String responsavel = data['responsavel'] ?? 'N/A';
                    String diasNoStatus = '';
                    final ts = data['timestamp'] as Timestamp?;
                    if (ts != null) {
                      final diffDias = DateTime.now()
                          .difference(ts.toDate())
                          .inDays;
                      diasNoStatus = diffDias <= 0
                          ? 'Hoje'
                          : diffDias == 1
                          ? '1 dia no status'
                          : '$diffDias dias no status';
                    }
                    markers.add(
                      Marker(
                        markerId: MarkerId(doc.id),
                        position: LatLng(
                          coordenadas.latitude,
                          coordenadas.longitude,
                        ),
                        infoWindow: InfoWindow(
                          title: 'TAG: $tag',
                          snippet: diasNoStatus.isEmpty
                              ? 'Responsável: $responsavel'
                              : 'Responsável: $responsavel\n$diasNoStatus',
                        ),
                      ),
                    );
                  }
                }

                return GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: const CameraPosition(
                    target: _posicaoInicial,
                    zoom: 12,
                  ),
                  markers: markers,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
