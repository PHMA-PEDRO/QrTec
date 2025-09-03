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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização dos Ativos em Transporte'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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
            return const Center(child: Text('Nenhum equipamento em transporte no momento.'));
          }

          // Cria um conjunto de marcadores para o mapa
          final Set<Marker> markers = {};
          final docs = snapshot.data!.docs;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final GeoPoint? coordenadas = data['coordenadas'] as GeoPoint?;
            
            if (coordenadas != null) {
              final String tag = data['tag'] ?? 'N/A';
              final String responsavel = data['responsavel'] ?? 'N/A';
              
              markers.add(
                Marker(
                  markerId: MarkerId(doc.id),
                  position: LatLng(coordenadas.latitude, coordenadas.longitude),
                  // Janela de informação que aparece ao tocar no marcador
                  infoWindow: InfoWindow(
                    title: 'TAG: $tag',
                    snippet: 'Responsável: $responsavel',
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
            markers: markers, // Adiciona os marcadores ao mapa
          );
        },
      ),
    );
  }
}
