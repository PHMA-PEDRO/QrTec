import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qrtec_final/telas/tela_estoque.dart';
import 'package:qrtec_final/telas/tela_historico_pessoal.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qrtec_final/services/auth_service.dart';

// Modelo simples para guardar os dados do projeto
class Projeto {
  final String id;
  final String nome;
  Projeto({required this.id, required this.nome});
}

class TelaHome extends StatefulWidget {
  const TelaHome({super.key});
  @override
  State<TelaHome> createState() => _TelaHomeState();
}

class _TelaHomeState extends State<TelaHome> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _responsavelController = TextEditingController();

  String _nomeUsuario = 'Carregando...';
  bool _isLoading = false;
  List<Projeto> _listaProjetos = [];
  String? _projetoSelecionadoId;
  bool _carregandoDadosIniciais = true;
  File? _imagemSelecionada;

  @override
  void initState() {
    super.initState();
    _buscarDadosIniciais();
  }

  @override
  void dispose() {
    _responsavelController.dispose();
    super.dispose();
  }

  Future<void> _buscarDadosIniciais() async {
    await _buscarNomeUsuario();
    if (mounted) {
      setState(() {
        _carregandoDadosIniciais = false;
      });
    }
  }

  Future<void> _buscarNomeUsuario() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && mounted) {
        final nome = doc.data()?['nome'] ?? 'Usuário';
        final projetosAcesso = List<String>.from(
          doc.data()?['projetos_acesso'] ?? [],
        );
        setState(() {
          _nomeUsuario = nome;
          _responsavelController.text = nome;
        });
        await _buscarProjetosDoUsuario(projetosAcesso);
      }
    }
  }

  Future<void> _buscarProjetosDoUsuario(List<String> projetosIds) async {
    if (projetosIds.isEmpty) {
      if (mounted) setState(() => _listaProjetos = []);
      return;
    }
    // Buscar projetos em paralelo para reduzir tempo total
    final futures = projetosIds.map(
      (id) => _firestore.collection('projetos').doc(id).get(),
    );
    final docs = await Future.wait(futures);
    final List<Projeto> projetosTemp = docs
        .where((doc) => doc.exists && (doc.data()?['status'] == 'ativo'))
        .map(
          (doc) => Projeto(
            id: doc.id,
            nome: doc.data()?['nomeProjeto'] ?? 'Nome indisponível',
          ),
        )
        .toList();
    if (mounted) {
      setState(() => _listaProjetos = projetosTemp);
    }
    await _carregarPreferenciaDeProjeto();
  }

  Future<void> _fazerLogout() async {
    try {
      // Usar o serviço de autenticação para limpeza completa
      final authService = AuthService();
      await authService.clearAllAuthData();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TelaLogin()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Se houver erro, forçar logout mesmo assim
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TelaLogin()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Future<void> _carregarPreferenciaDeProjeto() async {
    final prefs = await SharedPreferences.getInstance();
    final ultimoId = prefs.getString('ultimo_projeto_id');
    if (ultimoId != null && _listaProjetos.any((p) => p.id == ultimoId)) {
      if (mounted) {
        setState(() {
          _projetoSelecionadoId = ultimoId;
        });
      }
    }
  }

  Future<void> _salvarPreferenciaDeProjeto(String? projectId) async {
    if (projectId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_projeto_id', projectId);
  }

  Future<void> _capturarFoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? imagem = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (imagem != null && mounted) {
        setState(() => _imagemSelecionada = File(imagem.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao usar a câmera: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _registrarMovimentacao(String tipo) async {
    if (_projetoSelecionadoId == null ||
        _responsavelController.text.trim().isEmpty ||
        _imagemSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o projeto, tire a foto e confirme o responsável.',
          ),
        ),
      );
      return;
    }

    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    if (status.isPermanentlyDenied) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Permissão de Localização Necessária'),
            content: const Text(
              'Para registrar a movimentação, o aplicativo precisa de acesso à sua localização. Por favor, habilite a permissão nas configurações do seu dispositivo.',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Abrir Configurações'),
                onPressed: () {
                  openAppSettings();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A permissão de localização é obrigatória para continuar.',
            ),
          ),
        );
      }
      return;
    }

    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final String? qrCode = await navigator.push<String>(
        MaterialPageRoute(builder: (context) => const TelaScanner()),
      );

      if (qrCode != null) {
        final docEquipamento = await _firestore
            .collection('equipamentos')
            .doc(qrCode)
            .get();
        if (!docEquipamento.exists) {
          throw Exception(
            "Equipamento com a TAG '$qrCode' não encontrado no cadastro.",
          );
        }
        final dadosEquipamento = docEquipamento.data()!;
        final nomeEquipamento =
            dadosEquipamento['nome'] ?? 'Nome não encontrado';
        final descricaoEquipamento =
            dadosEquipamento['descricao'] ?? 'Sem descrição';
        final tipoEquipamento =
            dadosEquipamento['tipo_equipamento'] ?? 'PADRÃO';

        if (!mounted) return;
        final bool? confirmado = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Movimentação?'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TAG: $qrCode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Nome: $nomeEquipamento'),
                Text('Descrição: $descricaoEquipamento'),
                const Divider(height: 24),
                Text(
                  'Ação: $tipo de equipamento',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        );

        if (confirmado == true) {
          Position position = await Geolocator.getCurrentPosition();
          String enderecoAproximado = 'Endereço não encontrado';
          try {
            final placemarks = await placemarkFromCoordinates(
              position.latitude,
              position.longitude,
            );
            if (placemarks.isNotEmpty) {
              final place = placemarks.first;
              final rua = (place.thoroughfare?.trim().isNotEmpty == true)
                  ? place.thoroughfare!.trim()
                  : (place.street?.trim().isNotEmpty == true
                        ? place.street!.trim()
                        : 'Rua desconhecida');
              final numero = (place.subThoroughfare?.trim().isNotEmpty == true)
                  ? place.subThoroughfare!.trim()
                  : 's/n';
              final bairro = (place.subLocality?.trim().isNotEmpty == true)
                  ? place.subLocality!.trim()
                  : '';
              final cidade = (place.locality?.trim().isNotEmpty == true)
                  ? place.locality!.trim()
                  : (place.subAdministrativeArea?.trim().isNotEmpty == true
                        ? place.subAdministrativeArea!.trim()
                        : '');
              final estado =
                  (place.administrativeArea?.trim().isNotEmpty == true)
                  ? place.administrativeArea!.trim()
                  : '';
              final cep = (place.postalCode?.trim().isNotEmpty == true)
                  ? place.postalCode!.trim()
                  : '';

              final ruaNumero = '$rua, $numero';
              final cidadeEstado = [
                cidade,
                estado,
              ].where((s) => s.isNotEmpty).join(' - ');
              final partes = <String>[
                ruaNumero,
                if (bairro.isNotEmpty) bairro,
                if (cidadeEstado.isNotEmpty) cidadeEstado,
                if (cep.isNotEmpty) 'CEP: $cep',
              ];
              enderecoAproximado = partes.join(' • ');
            }
          } catch (e) {
            enderecoAproximado = 'Falha ao obter endereço';
          }

          final String nomeArquivo =
              '${DateTime.now().millisecondsSinceEpoch}_$qrCode.jpg';
          final Reference ref = _storage
              .ref()
              .child('movimentacoes_fotos')
              .child(nomeArquivo);
          await ref.putFile(_imagemSelecionada!);
          final String fotoUrl = await ref.getDownloadURL();
          final String responsavel = _responsavelController.text.trim();
          final String? userId = _auth.currentUser?.uid;
          final String nomeProjetoSelecionado = _listaProjetos
              .firstWhere((p) => p.id == _projetoSelecionadoId!)
              .nome;

          await _firestore.collection('movimentacoes').add({
            'tagEquipamento': qrCode,
            'responsavel': responsavel,
            'tipo': tipo,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': userId,
            'localizacao': enderecoAproximado,
            'coordenadas': GeoPoint(position.latitude, position.longitude),
            'projetoId': _projetoSelecionadoId,
            'nomeProjeto': nomeProjetoSelecionado,
            'fotoUrl': fotoUrl,
            'tipoEquipamento': tipoEquipamento,
          });

          final String novoStatus = (tipo == 'Entrada')
              ? 'Em Estoque'
              : 'Em Transporte';
          await _firestore.collection('estoque_atual').doc(qrCode).set({
            'tag': qrCode,
            'status': novoStatus,
            'ultimaMovimentacao': tipo,
            'timestamp': FieldValue.serverTimestamp(),
            'responsavel': responsavel,
            'localizacao': enderecoAproximado,
            'coordenadas': GeoPoint(position.latitude, position.longitude),
            'projetoId': _projetoSelecionadoId,
            'nomeProjeto': nomeProjetoSelecionado,
            'userId': userId,
            'fotoUrl': fotoUrl,
            'tipoEquipamento': tipoEquipamento,
            // Ao mudar o status, limpar marcação de pronto para envio
            'prontoParaEnvio': false,
            'prontoParaEnvioTimestamp': null,
          }, SetOptions(merge: true));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Equipamento $qrCode registrado com sucesso!'),
              ),
            );
            setState(() => _imagemSelecionada = null);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro ao registrar: ${e.toString().replaceAll("Exception: ", "")}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Olá, $_nomeUsuario!'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _fazerLogout,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_carregandoDadosIniciais)
            const Center(child: CircularProgressIndicator())
          else
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Registrar Movimentação',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 24),
                        if (_listaProjetos.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhum projeto vinculado a você.\nPeça a um administrador para vincular.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: '1. Selecione o Projeto',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.business_center),
                            ),
                            value: _projetoSelecionadoId,
                            items: _listaProjetos
                                .map(
                                  (projeto) => DropdownMenuItem(
                                    value: projeto.id,
                                    child: Text(projeto.nome),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _projetoSelecionadoId = value;
                              });
                              _salvarPreferenciaDeProjeto(value);
                            },
                          ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _responsavelController,
                          decoration: const InputDecoration(
                            labelText: '2. Seu Nome (Responsável)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                        _imagemSelecionada == null
                            ? SizedBox(
                                height: 100,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt, size: 40),
                                  label: const Text(
                                    '3. Tirar Foto Obrigatória',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade600,
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _capturarFoto,
                                ),
                              )
                            : Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.file(
                                        _imagemSelecionada!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    onPressed: () => setState(() {
                                      _imagemSelecionada = null;
                                    }),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_downward),
                                label: const Text('4. Entrada'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed:
                                    _isLoading || _imagemSelecionada == null
                                    ? null
                                    : () => _registrarMovimentacao('Entrada'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.arrow_upward),
                                label: const Text('4. Saída'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed:
                                    _isLoading || _imagemSelecionada == null
                                    ? null
                                    : () => _registrarMovimentacao('Saída'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Ver Estoque'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                        onPressed: () {
                          if (_projetoSelecionadoId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Por favor, selecione um projeto.',
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TelaEstoque(
                                projectId: _projetoSelecionadoId!,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_pin_circle_outlined),
                        label: const Text('Meu Histórico'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16),
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const TelaHistoricoPessoal(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
