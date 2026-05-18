import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';
import 'package:pulsewise/features/food_analysis/presentation/providers/food_macro_llm_service_provider.dart';

class FoodMacroCameraPage extends ConsumerStatefulWidget {
  const FoodMacroCameraPage({super.key});

  @override
  ConsumerState<FoodMacroCameraPage> createState() =>
      _FoodMacroCameraPageState();
}

class _FoodMacroCameraPageState extends ConsumerState<FoodMacroCameraPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodDescriptionController =
      TextEditingController();

  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];
  bool _isCameraLoading = true;
  bool _isAnalyzing = false;
  String? _errorMessage;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _foodDescriptionController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera({int? index}) async {
    setState(() {
      _isCameraLoading = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('Kamera tidak tersedia di perangkat ini.');
      }

      final nextIndex = index ?? _resolveDefaultCameraIndex(cameras);
      final nextController = CameraController(
        cameras[nextIndex],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController?.dispose();
      await nextController.initialize();

      if (!mounted) {
        await nextController.dispose();
        return;
      }

      setState(() {
        _availableCameras = cameras;
        _cameraIndex = nextIndex;
        _cameraController = nextController;
        _isCameraLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCameraLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  int _resolveDefaultCameraIndex(List<CameraDescription> cameras) {
    final backIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );
    return backIndex >= 0 ? backIndex : 0;
  }

  Future<void> _switchCamera() async {
    if (_availableCameras.length < 2 || _isCameraLoading || _isAnalyzing) {
      return;
    }

    final nextIndex = (_cameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(index: nextIndex);
  }

  Future<void> _captureAndAnalyze() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      AppToast.warning(context, 'Kamera belum siap.');
      return;
    }
    if (_isAnalyzing) return;

    try {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
      });

      final photo = await controller.takePicture();
      final imageFile = File(photo.path);
      final result =
          await ref.read(foodMacroLlmServiceProvider).analyzeFoodImage(
                imageFile,
                foodName: _foodNameController.text.trim(),
                userDescription: _foodDescriptionController.text.trim(),
              );

      if (!mounted) return;
      if (!result.hasValidFoodResult) {
        setState(() {
          _isAnalyzing = false;
          _errorMessage = result.validationMessage.isNotEmpty
              ? result.validationMessage
              : 'Foto ini tidak terlihat seperti makanan atau minuman. Coba ambil ulang.';
        });
        AppToast.warning(context, _errorMessage!);
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _errorMessage = null;
      });

      await _openAnalysisResultPage(
        imageFile: imageFile,
        analysis: result,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget buildCameraPreview(CameraController controller) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final previewSize = controller.value.previewSize!;

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewSize.height,
            height: previewSize.width,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }

  Future<void> _openAnalysisResultPage({
    required File imageFile,
    required FoodMacroAnalysis analysis,
  }) async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _FoodMacroAnalysisResultPage(
          imageFile: imageFile,
          analysis: analysis,
          userFoodName: _foodNameController.text.trim(),
          userDescription: _foodDescriptionController.text.trim(),
        ),
      ),
    );

    if (!mounted || result == null) return;

    final action = (result['action'] ?? '').toString();
    if (action != 'use') return;

    final analysisPayloadRaw = result['analysis'];
    if (analysisPayloadRaw is! Map) return;

    final payload = analysisPayloadRaw.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    payload['user_food_name'] = _foodNameController.text.trim();
    payload['user_description'] = _foodDescriptionController.text.trim();
    Navigator.of(context).pop(payload);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final hasPreview = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_isCameraLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  )
                else if (hasPreview)
                  buildCameraPreview(controller)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _errorMessage ?? 'Kamera tidak bisa dimuat.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x99000000),
                        Color(0x00000000),
                        Color(0xAA000000),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.35),
                              ),
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Foto Nutrisi Makanan',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (_availableCameras.length > 1)
                              IconButton(
                                onPressed: _switchCamera,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      Colors.black.withOpacity(0.35),
                                ),
                                icon: const Icon(
                                  Icons.cameraswitch_rounded,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.42),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: const Text(
                            'Isi nama atau deskripsi kalau mau, lalu ambil foto. Hasil nutrisi akan muncul di halaman berikutnya.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_isAnalyzing)
                  Container(
                    color: Colors.black.withOpacity(0.55),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Menganalisis foto makanan...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Makanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _foodNameController,
                      enabled: !_isAnalyzing,
                      decoration: InputDecoration(
                        hintText: 'Contoh: nasi padang, bakso, salad ayam',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE64060),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Deskripsi Tambahan (Opsional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _foodDescriptionController,
                      enabled: !_isAnalyzing,
                      minLines: 3,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: pakai santan, ada sambal, porsi besar, lebih banyak ayam',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE64060),
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _captureAndAnalyze,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text(
                          'Ambil Foto dan Lihat Hasil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodMacroAnalysisCard extends StatelessWidget {
  const _FoodMacroAnalysisCard({
    required this.analysis,
  });

  final FoodMacroAnalysis analysis;

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Estimasi Nutrisi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 12),
          _MacroRow(
            label: 'Makanan Terdeteksi',
            value: analysis.detectedFoods.isEmpty
                ? '-'
                : analysis.detectedFoods.join(', '),
          ),
          _MacroRow(
            label: 'Estimasi Porsi',
            value: analysis.portionEstimate.isEmpty
                ? '-'
                : analysis.portionEstimate,
          ),
          _MacroRow(
            label: 'Estimasi Gram',
            value: '${_formatNumber(analysis.portionGramsEstimate)} g',
          ),
          if (analysis.fdcFoodId.isNotEmpty)
            _MacroRow(
              label: 'FDC Food ID',
              value: analysis.fdcFoodId,
            ),
          _MacroRow(
            label: 'Kalori',
            value: '${_formatNumber(analysis.caloriesKcal)} kkal',
          ),
          _MacroRow(
            label: 'Protein',
            value: '${_formatNumber(analysis.proteinG)} g',
          ),
          _MacroRow(
            label: 'Karbohidrat',
            value: '${_formatNumber(analysis.carbsG)} g',
          ),
          _MacroRow(
            label: 'Gula',
            value: '${_formatNumber(analysis.sugarG)} g',
          ),
          _MacroRow(
            label: 'Serat',
            value: '${_formatNumber(analysis.fiberG)} g',
          ),
          _MacroRow(
            label: 'Lemak',
            value: '${_formatNumber(analysis.fatG)} g',
          ),
          _MacroRow(
            label: 'Lemak Jenuh',
            value: '${_formatNumber(analysis.saturatedFatG)} g',
          ),
          _MacroRow(
            label: 'Lemak Tak Jenuh Tunggal',
            value: '${_formatNumber(analysis.monounsaturatedFatG)} g',
          ),
          _MacroRow(
            label: 'Lemak Tak Jenuh Ganda',
            value: '${_formatNumber(analysis.polyunsaturatedFatG)} g',
          ),
          _MacroRow(
            label: 'Kolesterol',
            value: '${_formatNumber(analysis.cholesterolMg)} mg',
          ),
          _MacroRow(
            label: 'Kalsium',
            value: '${_formatNumber(analysis.calciumMg)} mg',
          ),
          _MacroRow(
            label: 'Confidence',
            value: analysis.confidence.isEmpty ? '-' : analysis.confidence,
          ),
          if (analysis.notes.isNotEmpty)
            _MacroRow(
              label: 'Catatan',
              value: analysis.notes,
            ),
        ],
      ),
    );
  }
}

class _FoodMacroAnalysisResultPage extends StatelessWidget {
  const _FoodMacroAnalysisResultPage({
    required this.imageFile,
    required this.analysis,
    required this.userFoodName,
    required this.userDescription,
  });

  final File imageFile;
  final FoodMacroAnalysis analysis;
  final String userFoodName;
  final String userDescription;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Hasil Analisis Nutrisi'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Pengguna',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MacroRow(
                            label: 'Nama Makanan',
                            value: userFoodName.isEmpty ? '-' : userFoodName,
                          ),
                          _MacroRow(
                            label: 'Deskripsi',
                            value:
                                userDescription.isEmpty ? '-' : userDescription,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FoodMacroAnalysisCard(analysis: analysis),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).pop(const {'action': 'retake'}),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Ambil Lagi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop({
                          'action': 'use',
                          'analysis': analysis.toJson(),
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Pakai Hasil',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7C2D12),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
