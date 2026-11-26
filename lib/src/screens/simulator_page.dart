import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';

import '../theme.dart';
import '../models/catalog_item.dart';
import '../services/catalog_service.dart';
import '../services/mqtt_service.dart';
import '../supabase_client.dart';
import '../widgets/mirrify_logo.dart';
import 'admin_page.dart';
import 'login_page.dart';

class SimulatorPage extends StatefulWidget {
  const SimulatorPage({Key? key}) : super(key: key);

  @override
  State<SimulatorPage> createState() => _SimulatorPageState();
}

class _SimulatorPageState extends State<SimulatorPage>
    with WidgetsBindingObserver {
  final MqttService _mqttService = MqttService();
  final CatalogService _catalogService = CatalogService();

  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _cameraReady = false;
  bool _cameraError = false;
  String _cameraErrorMsg = '';
  bool _mirrorMode = true;
  bool _useDemoAvatar = false;

  String _neoPixelMode = 'Natural (4500K)';
  Color _neoPixelColor = const Color(0xFFFBF6E9);

  CatalogItem? _activeVisual;
  String _selectedCategory = 'Todos';
  int _currentTabIndex = 0;

  double _overlayOpacity = 0.5;

  static const String _adminEmail = 'manucatarinavs2@gmail.com';

  bool get _isAdmin {
    final email = SupabaseService.currentUser?.email ?? '';
    return email.trim().toLowerCase() == _adminEmail.toLowerCase();
  }

  void _onMqttUpdate() {
    if (mounted) {
      setState(() {
        // Sincroniza o glow do NeoPixel com o estado real do LED no Wokwi
        final data = _mqttService.telemetry;
        if (data != null) {
          if (data.led) {
            if (_neoPixelColor == Colors.black12) {
              _neoPixelColor = const Color(0xFFFBF6E9);
            }
          } else {
            _neoPixelColor = Colors.black12;
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _mqttService.addListener(_onMqttUpdate);
    _mqttService.connect();

    _catalogService.addListener(_onCatalogChanged);

    if (_catalogService.items.isNotEmpty) {
      _activeVisual = _catalogService.items.first;
    }

    _initCamera();
  }

  // ─── PAINEL DE SENSORES ───────────────────────────────────────────────────
  Widget _buildSensorPanel() {
    final data = _mqttService.telemetry;
    final lowLight = data != null && data.light < 30;
    final distanceAlert = data != null &&
        data.presence &&
        (data.distance < 25 || data.distance > 120);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner de alerta: pouca luz -> análise não confiável
        if (lowLight)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withOpacity(0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pouca luz detectada (${data!.light}%). A análise pode não ser confiável. '
                    'Ajuste a iluminação NeoPixel ou aproxime-se de uma fonte de luz.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF5D4037),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Banner de alerta: distância fora da faixa ideal
        if (distanceAlert)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  data!.distance < 25
                      ? Icons.compress_rounded
                      : Icons.zoom_out_map_rounded,
                  color: Colors.blue.shade700,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    data.distance < 25
                        ? 'Você está muito perto do espelho. Afaste-se para uma análise precisa (25–120 cm).'
                        : 'Você está muito longe do espelho. Aproxime-se (25–120 cm).',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Painel principal dos sensores
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5DEFA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sensors_rounded,
                      color: AppPalette.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sensores do Mirrify',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _mqttService.connected
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _mqttService.connected ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: _mqttService.connected
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _mqttService.connectionMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 18),
              if (data == null)
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          color: Colors.grey, size: 34),
                      const SizedBox(height: 8),
                      Text(
                        'Aguardando telemetria do espelho...',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          color: AppPalette.textMuted,
                        ),
                      ),
                      if (!_mqttService.connected) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Verifique se o Wokwi está rodando e conectado ao broker.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _sensorCard(
                      'Presença (PIR)',
                      data.presence ? 'Detectada' : 'Ausente',
                      data.presence
                          ? Icons.person_rounded
                          : Icons.person_off_rounded,
                      data.presence ? Colors.green : Colors.grey,
                    ),
                    _sensorCard(
                      'Distância (HC-SR04)',
                      data.distance < 0
                          ? 'Sem leitura'
                          : '${data.distance.toStringAsFixed(1)} cm',
                      Icons.straighten_rounded,
                      Colors.blue,
                    ),
                    _sensorCard(
                      'Luminosidade (LDR)',
                      '${data.light}%',
                      Icons.light_mode_rounded,
                      data.light < 30 ? Colors.orange : Colors.amber.shade700,
                    ),
                    _sensorCard(
                      'Condição',
                      data.status.replaceAll('_', ' '),
                      Icons.check_circle_outline_rounded,
                      data.status == 'adequado'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _mqttService.connected
                          ? () {
                              _mqttService.sendCommand('led_on');
                              setState(() {
                                _neoPixelMode = 'Natural (4500K)';
                                _neoPixelColor = const Color(0xFFFBF6E9);
                              });
                            }
                          : null,
                      icon: const Icon(Icons.lightbulb_rounded),
                      label: const Text('Ligar LEDs'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _mqttService.connected
                          ? () {
                              _mqttService.sendCommand('led_off');
                              setState(() {
                                _neoPixelColor = Colors.black12;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: const Text('Desligar LEDs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sensorCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 145,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppPalette.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppPalette.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Divide a mensagem em duas linhas de até 16 caracteres, como no OLED.
  List<String> _quebrarParaOled(String texto) {
    if (texto.contains('\n')) {
      final partes = texto.split('\n');
      return [
        partes[0],
        partes.length > 1 ? partes[1] : '',
      ];
    }
    if (texto.length <= 16) return [texto, ''];
    return [
      texto.substring(0, 16),
      texto.substring(16, texto.length > 32 ? 32 : texto.length),
    ];
  }

  // ─── CICLO DE VIDA DA CÂMERA ─────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed &&
        !_useDemoAvatar &&
        (_cameraController == null ||
            !_cameraController!.value.isInitialized)) {
      _initCamera();
    }
  }

  Future<void> _stopCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    setState(() {
      _cameraError = false;
      _cameraReady = false;
      _useDemoAvatar = false;
    });

    await _stopCamera();

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraError = true;
          _cameraErrorMsg =
              'Nenhuma câmera foi encontrada neste dispositivo.';
        });
        return;
      }

      CameraDescription selectedCamera = _cameras.first;
      for (final camera in _cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      setState(() {
        _cameraReady = true;
        _cameraError = false;
      });
    } catch (error) {
      await _stopCamera();
      if (!mounted) return;

      final message = error.toString().toLowerCase();
      String userMessage;
      if (message.contains('notallowed') ||
          message.contains('permission') ||
          message.contains('denied')) {
        userMessage =
            'Permissão da câmera negada. Clique no cadeado ao lado do endereço, permita o acesso à câmera e tente novamente.';
      } else if (message.contains('notfound') ||
          message.contains('no camera')) {
        userMessage =
            'Nenhuma câmera foi encontrada neste dispositivo.';
      } else if (message.contains('in use') ||
          message.contains('notreadable') ||
          message.contains('busy')) {
        userMessage =
            'A câmera está sendo usada por outro aplicativo ou aba. Feche-a e tente novamente.';
      } else {
        userMessage =
            'Não foi possível iniciar a câmera. Use localhost ou HTTPS, permita o acesso e clique em "Tentar novamente".';
      }

      setState(() {
        _cameraError = true;
        _cameraErrorMsg = userMessage;
      });
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;

    final current = _cameraController?.description;
    CameraDescription next = _cameras.first;
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i] == current && i + 1 < _cameras.length) {
        next = _cameras[i + 1];
        break;
      }
    }

    await _stopCamera();

    try {
      final controller = CameraController(
        next,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      setState(() {
        _cameraReady = true;
        _cameraError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _cameraReady = false;
        _cameraError = true;
        _cameraErrorMsg =
            'Não foi possível trocar para esta câmera. $error';
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _mqttService.removeListener(_onMqttUpdate);
    _mqttService.disconnect();
    _stopCamera();
    _catalogService.removeListener(_onCatalogChanged);
    super.dispose();
  }

  void _onCatalogChanged() => setState(() {});

  Future<void> _handleLogout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'Todos'
        ? _catalogService.items
        : _catalogService.items
            .where((item) => item.category == _selectedCategory)
            .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      appBar: _buildAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= 950;
          final horizontalPadding = width < 600 ? 12.0 : 24.0;

          if (_currentTabIndex == 1) {
            return _buildGalleryView();
          }

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildMirrorView(),
                                const SizedBox(height: 18),
                                _buildSensorPanel(),
                                const SizedBox(height: 18),
                                _buildNeoPixelPanel(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 6,
                            child: _buildCatalogSection(filteredItems),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildMirrorView(),
                          const SizedBox(height: 18),
                          _buildSensorPanel(),
                          const SizedBox(height: 18),
                          _buildNeoPixelPanel(),
                          const SizedBox(height: 24),
                          _buildCatalogSection(filteredItems),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) {
          setState(() => _currentTabIndex = index);
        },
        selectedItemColor: AppPalette.secondary,
        unselectedItemColor: AppPalette.textMuted,
        backgroundColor: Colors.white,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
        ),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'Simulador',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _catalogService.savedGallery.isNotEmpty,
              label: Text('${_catalogService.savedGallery.length}'),
              child: const Icon(Icons.favorite_rounded),
            ),
            label: 'Minha Galeria',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF2C2448),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MirrifySparkle(size: 24, color: AppPalette.secondary),
          const SizedBox(width: 8),
          Text(
            'MIRRIFY',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: const Color(0xFF382A6A),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        if (_isAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminPage()),
              ),
              icon: const Icon(Icons.admin_panel_settings_rounded,
                  size: 18),
              label: const Text('Admin'),
              style: TextButton.styleFrom(
                foregroundColor: AppPalette.violet,
                textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        IconButton(
          tooltip: 'Sair',
          icon: const Icon(Icons.logout_rounded),
          onPressed: _handleLogout,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ─── ESPELHO ─────────────────────────────────────────────────────────────
  Widget _buildMirrorView() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: _neoPixelColor.withOpacity(0.65),
                blurRadius: 32,
                spreadRadius: 6,
              ),
              BoxShadow(
                color: AppPalette.secondary.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: _neoPixelColor, width: 8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildCameraLayer(),
                    if (_activeVisual != null) _buildVisualOverlay(),
                    _buildMirrorUI(),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_activeVisual != null) ...[
          const SizedBox(height: 16),
          _buildOpacitySlider(),
        ],
      ],
    );
  }

  Widget _buildCameraLayer() {
    if (_useDemoAvatar) {
      return Image.network(
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800&auto=format&fit=crop&q=80',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: const Color(0xFF1B1829),
          child: const Center(
            child: Icon(Icons.person, size: 80, color: AppPalette.lavender),
          ),
        ),
      );
    }

    if (_cameraError) {
      return Container(
        color: const Color(0xFF13111C),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white54, size: 44),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _cameraErrorMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 12.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _initCamera();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPalette.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _useDemoAvatar = true);
                  },
                  icon: const Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 18),
                  label: const Text('Usar modelo de teste'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: AppPalette.lavender),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (!_cameraReady ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Container(
        color: const Color(0xFF13111C),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppPalette.lavender),
                strokeWidth: 2.5,
              ),
              const SizedBox(height: 16),
              Text(
                'Iniciando o Espelho Inteligente...',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewSize = _cameraController!.value.previewSize;
    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: _mirrorMode
            ? (Matrix4.identity()..scale(-1.0, 1.0))
            : Matrix4.identity(),
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize?.height ?? 400,
            height: previewSize?.width ?? 300,
            child: CameraPreview(_cameraController!),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualOverlay() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: _overlayOpacity,
      child: Image.network(
        _activeVisual!.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildMirrorUI() {
    final telemetry = _mqttService.telemetry;
    final linhasOled = telemetry != null
        ? _quebrarParaOled(telemetry.message)
        : ['', ''];

    return Stack(
      fit: StackFit.expand,
      children: [
        // Badge do visual atual (topo)
        if (_activeVisual != null)
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppPalette.lavender.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const MirrifySparkle(
                            size: 14, color: AppPalette.lavender),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _activeVisual!.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '• ${_activeVisual!.category}',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFCDB7ED),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Mensagem do OLED sobre o espelho (rodapé esquerdo)
        if (telemetry != null)
          Positioned(
            bottom: 14,
            left: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F1E).withOpacity(0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4FC3F7).withOpacity(0.6),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    linhasOled[0].trim(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4FC3F7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (linhasOled[1].trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      linhasOled[1].trim(),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4FC3F7),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

        // Botões de ação (canto inferior direito)
        Positioned(
          bottom: 14,
          right: 14,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_useDemoAvatar)
                _mirrorActionBtn(
                  icon: Icons.videocam_rounded,
                  tooltip: 'Usar câmera ao vivo',
                  onTap: () {
                    setState(() => _useDemoAvatar = false);
                    _initCamera();
                  },
                ),
              if (_useDemoAvatar) const SizedBox(height: 8),
              if (_cameras.length > 1 && !_useDemoAvatar)
                _mirrorActionBtn(
                  icon: Icons.flip_camera_ios_rounded,
                  tooltip: 'Virar câmera',
                  onTap: _switchCamera,
                ),
              if (_cameras.length > 1 && !_useDemoAvatar)
                const SizedBox(height: 8),
              _mirrorActionBtn(
                icon:
                    _mirrorMode ? Icons.flip_rounded : Icons.flip_outlined,
                tooltip: _mirrorMode ? 'Desespelhar' : 'Espelhar',
                onTap: () => setState(() => _mirrorMode = !_mirrorMode),
              ),
              if (_activeVisual != null) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    _catalogService.toggleSave(_activeVisual!.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppPalette.secondary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        content: Text(
                          _activeVisual!.isSaved
                              ? 'Removido da galeria.'
                              : '✨ Visual salvo na sua galeria!',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _activeVisual!.isSaved
                          ? const Color(0xFFE91E63)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _activeVisual!.isSaved
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: _activeVisual!.isSaved
                              ? Colors.white
                              : const Color(0xFFE91E63),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _activeVisual!.isSaved
                              ? 'Salvo!'
                              : 'Salvar look',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _activeVisual!.isSaved
                                ? Colors.white
                                : const Color(0xFF2C2448),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _mirrorActionBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
              ),
            ],
          ),
          child:
              Icon(icon, color: const Color(0xFF2C2448), size: 20),
        ),
      ),
    );
  }

  Widget _buildOpacitySlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5DEFA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded,
                  color: AppPalette.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Intensidade do visual:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C2448),
                ),
              ),
              const Spacer(),
              Text(
                '${(_overlayOpacity * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.secondary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppPalette.secondary,
              inactiveTrackColor:
                  AppPalette.lavender.withOpacity(0.4),
              thumbColor: AppPalette.secondary,
              overlayColor: AppPalette.secondary.withOpacity(0.15),
            ),
            child: Slider(
              value: _overlayOpacity,
              min: 0.0,
              max: 1.0,
              onChanged: (val) => setState(() => _overlayOpacity = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Só câmera',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppPalette.textMuted)),
              Text('Só visual',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, color: AppPalette.textMuted)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── PAINEL NEOPIXEL ─────────────────────────────────────────────────────
  Widget _buildNeoPixelPanel() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5DEFA), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppPalette.lavender.withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neoPixelColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.light_mode_rounded,
                  color: _neoPixelColor == const Color(0xFFFBF6E9)
                      ? const Color(0xFFFFA000)
                      : AppPalette.periwinkle,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Iluminação NeoPixel da Moldura',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C2448),
                      ),
                    ),
                    Text(
                      'Escolha o tom de luz ideal para análise',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildNeoPixelChip('Natural (4500K)', const Color(0xFFFBF6E9)),
              _buildNeoPixelChip('Quente (3000K)', const Color(0xFFFFE0B2)),
              _buildNeoPixelChip('Fria (6000K)', const Color(0xFFE1F5FE)),
              _buildNeoPixelChip('Sunset Glamour', const Color(0xFFFFCDD2)),
              _buildNeoPixelChip('Lilás Dreamy', const Color(0xFFEDE7F6)),
              _buildNeoPixelChip('Desligado', Colors.transparent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNeoPixelChip(String label, Color color) {
    final isSelected = _neoPixelMode == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _neoPixelMode = label;
          _neoPixelColor =
              color == Colors.transparent ? Colors.black12 : color;
        });
        // Envia comando para o Wokwi também
        if (_mqttService.connected) {
          if (color == Colors.transparent) {
            _mqttService.sendCommand('led_off');
          } else {
            _mqttService.sendCommand('led_on');
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPalette.secondary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppPalette.secondary
                : const Color(0xFFE2DCF0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color == Colors.transparent
                    ? Colors.black26
                    : color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black12),
                boxShadow: color != Colors.transparent
                    ? [
                        BoxShadow(
                            color: color.withOpacity(0.6),
                            blurRadius: 6)
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppPalette.secondary
                    : AppPalette.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CATÁLOGO ────────────────────────────────────────────────────────────
  Widget _buildCatalogSection(List<CatalogItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Escolha seu Visual',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2C2448),
                    ),
                  ),
                  Text(
                    'Selecione para simular ao vivo no espelho',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppPalette.lavender.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length} visuais',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppPalette.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _catalogService.categories.map((cat) {
              final isSel = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSel,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                  selectedColor: AppPalette.secondary,
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight:
                        isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? Colors.white : AppPalette.textDark,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.76,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            final isActive = _activeVisual?.id == item.id;

            return InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _activeVisual = item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isActive
                        ? AppPalette.secondary
                        : const Color(0xFFE5DEFA),
                    width: isActive ? 2.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isActive
                          ? AppPalette.secondary.withOpacity(0.22)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: isActive ? 14 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppPalette.mint,
                                child: const Icon(
                                    Icons.image_not_supported_rounded),
                              ),
                            ),
                            if (isActive)
                              Container(
                                color: AppPalette.secondary
                                    .withOpacity(0.22),
                                child: const Center(
                                  child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 16,
                                    child: Icon(Icons.check,
                                        color: AppPalette.secondary,
                                        size: 20),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 7,
                              right: 7,
                              child: GestureDetector(
                                onTap: () =>
                                    _catalogService.toggleSave(item.id),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.9),
                                  child: Icon(
                                    item.isSaved
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: const Color(0xFFE91E63),
                                    size: 15,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C2448),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.category,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppPalette.violet,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ─── GALERIA ─────────────────────────────────────────────────────────────
  Widget _buildGalleryView() {
    final saved = _catalogService.savedGallery;

    if (saved.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppPalette.lavender.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_border_rounded,
                    size: 36, color: AppPalette.secondary),
              ),
              const SizedBox(height: 18),
              Text(
                'Sua galeria está vazia',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C2448),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simule looks no espelho ao vivo e salve seus favoritos aqui.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, color: AppPalette.textMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentTabIndex = 0),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Explorar Catálogo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPalette.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Minha Galeria',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C2448),
            ),
          ),
          Text(
            'Looks salvos no seu Espelho Inteligente Mirrify',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: saved.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final item = saved[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: Image.network(item.imageUrl,
                            fit: BoxFit.cover),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.category,
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppPalette.violet),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.red,
                                size: 20),
                            onPressed: () =>
                                _catalogService.toggleSave(item.id),
                            tooltip: 'Remover',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}