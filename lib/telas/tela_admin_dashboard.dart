// lib/telas/tela_admin_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:qrtec_final/telas/tela_busca_historico.dart';
import 'package:qrtec_final/telas/tela_cadastro_equipamento.dart';
import 'package:qrtec_final/telas/tela_cadastro_projeto.dart';
import 'package:qrtec_final/telas/tela_gerenciar_usuarios.dart';
import 'package:qrtec_final/telas/tela_gerenciar_vinculos.dart';
import 'package:qrtec_final/telas/tela_historico_geral.dart';
import 'package:qrtec_final/telas/tela_lista_projetos_admin.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_mapa_ativos.dart';
import 'package:qrtec_final/telas/tela_aprovar_envio.dart';
import 'package:qrtec_final/services/auth_service.dart';

class TelaAdminDashboard extends StatelessWidget {
  const TelaAdminDashboard({super.key});

  Future<void> _fazerLogout(BuildContext context) async {
    try {
      // Usar o serviço de autenticação para limpeza completa
      final authService = AuthService();
      await authService.clearAllAuthData();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TelaLogin()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Se houver erro, forçar logout mesmo assim
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TelaLogin()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  // Nova função de navegação para os cards interativos
  void _navegarParaHistoricoFiltrado(
    BuildContext context,
    FiltroHistorico filtro,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaHistoricoGeral(filtroInicial: filtro),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel do Administrador'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _fazerLogout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Visão Geral',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              DashboardStatCard(
                stream: firestore
                    .collection('projetos')
                    .where('status', isEqualTo: 'ativo')
                    .snapshots(),
                icon: Icons.business_center,
                label: 'Projetos Ativos',
                color: Colors.blue.shade700,
              ),
              DashboardStatCard(
                stream: firestore
                    .collection('equipamentos')
                    .where('status_operacional', isEqualTo: 'Ativo')
                    .snapshots(),
                icon: Icons.computer,
                label: 'Equip. Ativos',
                color: Colors.teal.shade700,
              ),
              // Card "Em Estoque" agora é clicável
              InkWell(
                onTap: () => _navegarParaHistoricoFiltrado(
                  context,
                  FiltroHistorico.entradas,
                ),
                child: DashboardStatCard(
                  stream: firestore
                      .collection('estoque_atual')
                      .where('status', isEqualTo: 'Em Estoque')
                      .snapshots(),
                  icon: Icons.inventory_2,
                  label: 'Em Estoque',
                  color: Colors.green.shade700,
                ),
              ),
              // Card "Em Transporte" agora é clicável
              InkWell(
                onTap: () => _navegarParaHistoricoFiltrado(
                  context,
                  FiltroHistorico.saidas,
                ),
                child: DashboardStatCard(
                  stream: firestore
                      .collection('estoque_atual')
                      .where('status', isEqualTo: 'Em Transporte')
                      .snapshots(),
                  icon: Icons.local_shipping,
                  label: 'Em Transporte',
                  color: Colors.orange.shade800,
                ),
              ),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaAprovarEnvio(),
                  ),
                ),
                child: DashboardStatCard(
                  stream: firestore
                      .collection('estoque_atual')
                      .where('status', isEqualTo: 'Em Estoque')
                      .where('prontoParaEnvio', isEqualTo: true)
                      .snapshots(),
                  icon: Icons.playlist_add_check_circle,
                  label: 'Aguardando Envio',
                  color: Colors.indigo.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Ações de Gerenciamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4, // Alterado para 4 colunas
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8, // Ajustado para melhor proporção
            children: [
              DashboardActionButton(
                icon: Icons.add_business_outlined,
                label: 'Projetos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaCadastroProjeto(),
                  ),
                ),
              ),
              DashboardActionButton(
                icon: Icons.add_moderator_outlined,
                label: 'Equipamentos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaGerenciamentoEquipamentos(),
                  ),
                ),
              ),
              DashboardActionButton(
                icon: Icons.people_alt_outlined,
                label: 'Vínculos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaGerenciarVinculos(),
                  ),
                ),
              ),
              // Novo botão "Gerenciar Usuários"
              DashboardActionButton(
                icon: Icons.manage_accounts,
                label: 'Usuários',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaGerenciarUsuarios(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Consultas e Relatórios',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 4, // Alterado para 4 colunas
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8, // Ajustado para melhor proporção
            children: [
              DashboardActionButton(
                icon: Icons.inventory_2_outlined,
                label: 'Estoques',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaListaProjetosAdmin(),
                  ),
                ),
              ),
              DashboardActionButton(
                icon: Icons.map_outlined,
                label: 'Mapa de Ativos',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaMapaAtivos(),
                  ),
                ),
              ),
              DashboardActionButton(
                icon: Icons.history_outlined,
                label: 'Rastrear TAG',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaBuscaHistorico(),
                  ),
                ),
              ),
              DashboardActionButton(
                icon: Icons.dynamic_feed_outlined,
                label: 'Histórico Geral',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TelaHistoricoGeral(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// WIDGET REUTILIZÁVEL PARA OS CARDS DE ESTATÍSTICA
class DashboardStatCard extends StatelessWidget {
  final Stream<QuerySnapshot> stream;
  final IconData icon;
  final String label;
  final Color color;
  const DashboardStatCard({
    super.key,
    required this.stream,
    required this.icon,
    required this.label,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: stream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (!snapshot.hasData) return const Center(child: Text('...'));
            final int count = snapshot.data!.docs.length;
            return Row(
              children: [
                Icon(icon, size: 32, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// WIDGET REUTILIZÁVEL PARA OS BOTÕES DE AÇÃO
class DashboardActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const DashboardActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Colors.indigo), // Tamanho reduzido
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12), // Fonte menor
              ),
            ],
          ),
        ),
      ),
    );
  }
}
