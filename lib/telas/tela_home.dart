// lib/telas/tela_home.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:qrtec_final/telas/tela_estoque.dart';
import 'package:qrtec_final/telas/tela_login.dart';
import 'package:qrtec_final/telas/tela_scanner.dart';

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
  bool _carregandoProjetos = true;

  File? _imagemSelecionada;

  @override
  void initState() {
    super.initState();
    _buscarDadosIniciais();
  }

  Future<void> _buscarDadosIniciais() async {
    await _buscarNomeUsuario();
    await _buscarProjetosDoUsuario();
  }

  Future<void> _buscarNomeUsuario() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nomeUsuario = doc.data()?['nome'] ?? 'Usuário';
        });
      }
    }
  }

  Future<void> _buscarProjetosDoUsuario() async {
    setState(() { _carregandoProjetos = true; });
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (!userDoc.exists) {
        return;
      }
      final List<dynamic> projetosIds = userDoc.data()?['projetos_acesso'] ?? [];
      if (projetosIds.isEmpty) {
        if (mounted) {
          setState(() {
            _listaProjetos = [];
          });
        }
        return;
      }

      List<Projeto> projetosTemp = [];
      for (String id in projetosIds) {
        final projetoDoc = await _firestore.collection('projetos').doc(id).get();
        if (projetoDoc.exists) {
          projetosTemp.add(Projeto(
            id: projetoDoc.id,
            nome: projetoDoc.data()?['nomeProjeto'] ?? 'Nome indisponível',
          ));
        }
      }
      if (mounted) {
        setState(() {
          _listaProjetos = projetosTemp;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregandoProjetos = false;
        });
      }
    }
  }

  Future<void> _fazerLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TelaLogin()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: source, imageQuality: 80);

    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  void _mostrarOpcoesDeImagem() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeria'),
                onTap: () {
                  _pegarImagem(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Câmera'),
                onTap: () {
                  _pegarImagem(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _registrarMovimentacao(String tipo) async {
    // CORREÇÃO: Adicionadas chaves {}
    if (_projetoSelecionadoId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione um projeto primeiro.')));
      }
      return;
    }
    // CORREÇÃO: Adicionadas chaves {}
    if (_responsavelController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, preencha o nome do responsável.')));
      }
      return;
    }
    // CORREÇÃO: Adicionadas chaves {}
    if (_isLoading) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) {
        return;
      }
      final String? qrCode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const TelaScanner()));

      if (qrCode != null) {
        bool servicoHabilitado = await Geolocator.isLocationServiceEnabled();
        if (!servicoHabilitado) {
          throw Exception('Serviço de localização desabilitado.');
        }

        LocationPermission permissao = await Geolocator.checkPermission();
        if (permissao == LocationPermission.denied) {
          permissao = await Geolocator.requestPermission();
          if (permissao == LocationPermission.denied) {
            throw Exception('Permissão de localização negada.');
          }
        }
        if (permissao == LocationPermission.deniedForever) {
          throw Exception('Permissão de localização negada permanentemente.');
        }

        Position position = await Geolocator.getCurrentPosition();
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        String endereco = 'Localização não encontrada';
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          endereco = "${place.street}, ${place.subLocality}, ${place.locality} - ${place.administrativeArea}";
        }

        String? fotoUrl;
        if (_imagemSelecionada != null) {
          final String nomeArquivo = '${DateTime.now().millisecondsSinceEpoch}_$qrCode.jpg';
          final Reference ref = _storage.ref().child('movimentacoes_fotos').child(nomeArquivo);
          await ref.putFile(_imagemSelecionada!);
          fotoUrl = await ref.getDownloadURL();
        }

        final String responsavel = _responsavelController.text.trim();
        final String? userId = _auth.currentUser?.uid;

        await _firestore.collection('movimentacoes').add({
          'tagEquipamento': qrCode,
          'responsavel': responsavel,
          'tipo': tipo,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': userId,
          'localizacao': endereco,
          'projetoId': _projetoSelecionadoId,
          'fotoUrl': fotoUrl,
        });

        final String novoStatus = (tipo == 'Entrada') ? 'Em Estoque' : 'Em Transporte';
        await _firestore.collection('estoque_atual').doc(qrCode).set({
          'tag': qrCode,
          'status': novoStatus,
          'ultimaMovimentacao': tipo,
          'timestamp': FieldValue.serverTimestamp(),
          'responsavel': responsavel,
          'localizacao': endereco,
          'projetoId': _projetoSelecionadoId,
          'userId': userId,
          'fotoUrl': fotoUrl,
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Equipamento $qrCode registrado com sucesso!')));
          setState(() {
            _imagemSelecionada = null;
            _responsavelController.clear();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao registrar: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, $_nomeUsuario!'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [IconButton(icon: const Icon(Icons.logout), tooltip: 'Sair', onPressed: _fazerLogout)],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_carregandoProjetos) ...[
                    const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                  ] else if (_listaProjetos.isEmpty) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Nenhum projeto vinculado a você.\nPeça a um administrador para vincular.', textAlign: TextAlign.center),
                      ),
                    )
                  ] else ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Selecione o Projeto', border: OutlineInputBorder()),
                      value: _projetoSelecionadoId,
                      items: _listaProjetos.map((projeto) => DropdownMenuItem(value: projeto.id, child: Text(projeto.nome))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _projetoSelecionadoId = value;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(controller: _responsavelController, decoration: const InputDecoration(labelText: 'Seu Nome (Responsável)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_pin_rounded))),
                  const SizedBox(height: 16),
                  
                  OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Anexar Foto (Opcional)'),
                    onPressed: _mostrarOpcoesDeImagem,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: _imagemSelecionada != null ? Colors.green : Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_imagemSelecionada != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(_imagemSelecionada!, fit: BoxFit.cover),
                          ),
                        ),
                        IconButton(
                          icon: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, color: Colors.white, size: 18)),
                          onPressed: () {
                            setState(() {
                              _imagemSelecionada = null;
                            });
                          },
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Registrar Entrada'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16)),
                    onPressed: _isLoading || _projetoSelecionadoId == null ? null : () => _registrarMovimentacao('Entrada'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Registrar Saída'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16)),
                    onPressed: _isLoading || _projetoSelecionadoId == null ? null : () => _registrarMovimentacao('Saída'),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('Ver Estoque Atual'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 16)),
                    onPressed: () {
                      if (_projetoSelecionadoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, selecione um projeto para ver o estoque.')));
                        return;
                      }
                      Navigator.push(context, MaterialPageRoute(builder: (context) => TelaEstoque(projectId: _projetoSelecionadoId!)));
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              // CORREÇÃO: Uso de Colors.black54 para remover o aviso
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}