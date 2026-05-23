import 'dart:io';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';
import 'package:pulsewise/features/food_analysis/presentation/providers/food_nutrition_estimate_api_provider.dart';

typedef SaveFoodConsumptionCallback = Future<void> Function(
  Map<String, dynamic> payload,
);

class FoodMacroCameraPage extends ConsumerStatefulWidget {
  const FoodMacroCameraPage({
    super.key,
    this.onSaveConsumption,
    this.consumptionTypeLabel,
    this.consumptionTypeApi,
    this.consumptionTime,
  });

  final SaveFoodConsumptionCallback? onSaveConsumption;
  final String? consumptionTypeLabel;
  final String? consumptionTypeApi;
  final String? consumptionTime;

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

  bool _validateMealName() {
    final mealName = _foodNameController.text.trim();
    if (mealName.isEmpty) {
      setState(() {
        _errorMessage = 'Nama makanan wajib diisi sebelum analisis.';
      });
      AppToast.warning(context, _errorMessage!);
      return false;
    }
    return true;
  }

  Future<void> _analyzeImageFile(File imageFile) async {
    if (!_validateMealName() || _isAnalyzing) return;

    final mealName = _foodNameController.text.trim();

    try {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
      });

      final result =
          await ref.read(foodNutritionEstimateApiProvider).estimateNutrition(
                imageFile: imageFile,
                mealName: mealName,
                mealDescription: _foodDescriptionController.text.trim(),
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

  Future<void> _captureAndAnalyze() async {
    if (!_validateMealName()) return;

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      AppToast.warning(context, 'Kamera belum siap.');
      return;
    }
    if (_isAnalyzing) return;

    try {
      final photo = await controller.takePicture();
      await _analyzeImageFile(File(photo.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickFromGallery() async {
    if (!_validateMealName() || _isAnalyzing) return;

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
      allowMultiple: false,
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return;

    final selected = picked.files.first;
    const maxImageBytes = 10 * 1024 * 1024;
    if (selected.size > maxImageBytes) {
      if (!mounted) return;
      AppToast.warning(context, 'Ukuran gambar maksimal 10 MB.');
      return;
    }

    String? sourcePath = selected.path;
    if ((sourcePath == null || sourcePath.isEmpty) && selected.bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final fallbackName =
          selected.name.isEmpty ? 'food_gallery.jpg' : selected.name;
      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$fallbackName',
      );
      await tempFile.writeAsBytes(selected.bytes!, flush: true);
      sourcePath = tempFile.path;
    }

    if (sourcePath == null || sourcePath.isEmpty) {
      if (!mounted) return;
      AppToast.warning(context, 'File gambar tidak valid.');
      return;
    }

    await _analyzeImageFile(File(sourcePath));
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

  String _resolveConsumptionTypeLabel() {
    final raw = widget.consumptionTypeLabel?.trim() ?? '';
    return _normalizeMealCategoryValue(raw);
  }

  String _resolveConsumptionTypeApi() {
    final raw = widget.consumptionTypeApi?.trim() ?? '';
    return _normalizeMealCategoryValue(raw);
  }

  String _normalizeMealCategoryValue(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'makanan ringan':
      case 'snack':
      case 'other':
      case 'cemilan':
      case 'camilan':
      case 'lainnya':
        return 'Makanan Ringan';
      case 'minuman':
      case 'drink':
        return 'Minuman';
      case 'makanan berat':
      case 'breakfast':
      case 'sarapan':
      case 'lunch':
      case 'makan siang':
      case 'dinner':
      case 'makan malam':
      case 'food':
      case 'makanan':
      default:
        return 'Makanan Berat';
    }
  }

  String _resolveMealCategory(FoodMacroAnalysis analysis) {
    final category = analysis.mealCategory.trim();
    if (category.isEmpty) return _resolveConsumptionTypeApi();
    return _normalizeMealCategoryValue(category);
  }

  String _resolveMealCategoryLabel(FoodMacroAnalysis analysis) {
    final label = _resolveMealCategory(analysis).trim();
    return label.isEmpty ? _resolveConsumptionTypeLabel() : label;
  }

  String _resolveConsumptionTime() {
    final raw = widget.consumptionTime?.trim() ?? '';
    if (raw.isNotEmpty) return raw;

    final now = TimeOfDay.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _resolvePortion(FoodMacroAnalysis analysis) {
    if (analysis.portionEstimate.isNotEmpty) {
      return FoodMacroAnalysis.truncatePortionText(analysis.portionEstimate);
    }

    if (analysis.portionGramsEstimate > 0) {
      return '${analysis.portionGramsEstimate.round()} g';
    }

    return '1 porsi';
  }

  String _buildConsumptionNote(FoodMacroAnalysis analysis) {
    final userDescription = _foodDescriptionController.text.trim();
    final analysisNotes = analysis.notes.trim();
    final noteParts = <String>[
      if (userDescription.isNotEmpty) userDescription,
      if (analysisNotes.isNotEmpty) 'Analisis foto: $analysisNotes',
    ];

    return noteParts.join('\n\n');
  }

  Map<String, dynamic> _buildConsumptionPayload(FoodMacroAnalysis analysis) {
    final userFoodName = _foodNameController.text.trim();
    final suggestedName = analysis.suggestedName.trim();
    final resolvedName = userFoodName.isNotEmpty
        ? userFoodName
        : (suggestedName.isNotEmpty ? suggestedName : 'Makanan');

    return {
      'typeLabel': _resolveMealCategoryLabel(analysis),
      'type': _resolveMealCategory(analysis),
      'name': resolvedName,
      'portion': _resolvePortion(analysis),
      'time': _resolveConsumptionTime(),
      'useCurrentTime': true,
      'note': _buildConsumptionNote(analysis),
      'foodMacroAnalysis': analysis.toJson(),
      'nutritionPayload': analysis.toDiaryNutritionPayload(),
    };
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
          onSaveConsumption: widget.onSaveConsumption == null
              ? null
              : () => widget.onSaveConsumption!(
                    _buildConsumptionPayload(analysis),
                  ),
        ),
      ),
    );

    if (!mounted || result == null) return;

    final action = (result['action'] ?? '').toString();
    if (action == 'saved') {
      Navigator.of(context).pop(const {'action': 'saved'});
      return;
    }
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
                        // Container(
                        //   width: double.infinity,
                        //   padding: const EdgeInsets.all(14),
                        //   decoration: BoxDecoration(
                        //     color: Colors.black.withOpacity(0.42),
                        //     borderRadius: BorderRadius.circular(16),
                        //     border: Border.all(
                        //       color: Colors.white.withOpacity(0.15),
                        //     ),
                        //   ),
                        //   child: const Text(
                        //     'Isi nama atau deskripsi kalau mau, lalu ambil foto. Hasil nutrisi akan muncul di halaman berikutnya dan bisa langsung disimpan.',
                        //     textAlign: TextAlign.center,
                        //     style: TextStyle(
                        //       color: Colors.white,
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w600,
                        //       height: 1.4,
                        //     ),
                        //   ),
                        // ),
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
                      'Nama Makanan (Wajib)',
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
                    // Container(
                    //   width: double.infinity,
                    //   padding: const EdgeInsets.all(14),
                    //   decoration: BoxDecoration(
                    //     color: const Color(0xFFFFFBFB),
                    //     borderRadius: BorderRadius.circular(16),
                    //     border: Border.all(color: const Color(0xFFFBC8D2)),
                    //   ),
                    //   child: const Text(
                    //     'Pilih cara ambil gambar. Bisa foto langsung dari kamera atau pilih gambar dari galeri.',
                    //     style: TextStyle(
                    //       fontSize: 16,
                    //       fontWeight: FontWeight.w600,
                    //       color: Color(0xFF475569),
                    //       height: 1.45,
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isAnalyzing ? null : _pickFromGallery,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF475569),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text(
                              'Pilih Galeri',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isAnalyzing || !hasPreview
                                ? null
                                : _captureAndAnalyze,
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
                              'Ambil Foto',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!hasPreview) ...[
                      const SizedBox(height: 10),
                      const Text(
                        'Kamera belum tersedia, tapi Anda tetap bisa pilih gambar dari galeri.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                    ],
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

  List<_NutritionMetricData> get _nutritionRows => [
        _NutritionMetricData(
          label: 'Estimasi Gram',
          amount: _formatNumber(analysis.portionGramsEstimate),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Kalori',
          amount: _formatNumber(analysis.caloriesKcal),
          unit: 'kkal',
        ),
        _NutritionMetricData(
          label: 'Protein',
          amount: _formatNumber(analysis.proteinG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Karbohidrat',
          amount: _formatNumber(analysis.carbsG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Gula',
          amount: _formatNumber(analysis.sugarG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Serat',
          amount: _formatNumber(analysis.fiberG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Lemak Total',
          amount: _formatNumber(analysis.fatG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Lemak Jenuh',
          amount: _formatNumber(analysis.saturatedFatG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Lemak Tak Jenuh Tunggal',
          amount: _formatNumber(analysis.monounsaturatedFatG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Lemak Tak Jenuh Ganda',
          amount: _formatNumber(analysis.polyunsaturatedFatG),
          unit: 'g',
        ),
        _NutritionMetricData(
          label: 'Kolesterol',
          amount: _formatNumber(analysis.cholesterolMg),
          unit: 'mg',
        ),
        _NutritionMetricData(
          label: 'Kalsium',
          amount: _formatNumber(analysis.calciumMg),
          unit: 'mg',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Hasil Estimasi Nutrisi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              if (analysis.confidence.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Akurasi ${analysis.confidence}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _AnalysisHighlightChip(
                label: 'Kategori',
                value: analysis.mealCategoryLabel,
              ),
              _AnalysisHighlightChip(
                label: 'Jumlah Data',
                value: '${analysis.detectedFoods.length} item',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                if (analysis.fdcFoodId.isNotEmpty)
                  _MacroRow(
                    label: 'FDC Food ID',
                    value: analysis.fdcFoodId,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _NutritionMetricsTable(rows: _nutritionRows),
          if (analysis.notes.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _MacroRow(
                label: 'Catatan Analisis',
                value: analysis.notes,
              ),
            ),
        ],
      ),
    );
  }
}

class _AnalysisHighlightChip extends StatelessWidget {
  const _AnalysisHighlightChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C2D12),
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionMetricData {
  const _NutritionMetricData({
    required this.label,
    required this.amount,
    required this.unit,
  });

  final String label;
  final String amount;
  final String unit;
}

class _NutritionMetricsTable extends StatelessWidget {
  const _NutritionMetricsTable({
    required this.rows,
  });

  final List<_NutritionMetricData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tabel Nutrisi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(0.9),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color(0xFFFED7AA),
                ),
                children: [
                  _NutritionTableCell(
                    text: 'Komponen',
                    isHeader: true,
                  ),
                  _NutritionTableCell(
                    text: 'Jumlah',
                    isHeader: true,
                    textAlign: TextAlign.end,
                  ),
                  _NutritionTableCell(
                    text: 'Satuan',
                    isHeader: true,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              for (var index = 0; index < rows.length; index++)
                TableRow(
                  decoration: BoxDecoration(
                    color:
                        index.isEven ? Colors.white : const Color(0xFFFFFBF5),
                  ),
                  children: [
                    _NutritionTableCell(text: rows[index].label),
                    _NutritionTableCell(
                      text: rows[index].amount,
                      textAlign: TextAlign.end,
                    ),
                    _NutritionTableCell(
                      text: rows[index].unit,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionTableCell extends StatelessWidget {
  const _NutritionTableCell({
    required this.text,
    this.isHeader = false,
    this.textAlign = TextAlign.start,
  });

  final String text;
  final bool isHeader;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFFED7AA)),
        ),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: isHeader ? 15 : 15,
          fontWeight: isHeader ? FontWeight.w800 : FontWeight.w600,
          color: isHeader ? const Color(0xFF9A3412) : const Color(0xFF7C2D12),
          height: 1.35,
        ),
      ),
    );
  }
}

class _FoodMacroAnalysisResultPage extends StatefulWidget {
  const _FoodMacroAnalysisResultPage({
    required this.imageFile,
    required this.analysis,
    required this.userFoodName,
    required this.userDescription,
    this.onSaveConsumption,
  });

  final File imageFile;
  final FoodMacroAnalysis analysis;
  final String userFoodName;
  final String userDescription;

  final Future<void> Function()? onSaveConsumption;

  @override
  State<_FoodMacroAnalysisResultPage> createState() =>
      _FoodMacroAnalysisResultPageState();
}

class _FoodMacroAnalysisResultPageState
    extends State<_FoodMacroAnalysisResultPage> {
  bool _isSaving = false;
  String? _saveError;

  Future<void> _handleUseResult() async {
    if (_isSaving) return;

    final onSaveConsumption = widget.onSaveConsumption;
    if (onSaveConsumption == null) {
      Navigator.of(context).pop({
        'action': 'use',
        'analysis': widget.analysis.toJson(),
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await onSaveConsumption();
      if (!mounted) return;
      Navigator.of(context).pop(const {'action': 'saved'});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Hasil Analisis Nutrisi',
        onBackPressed: () {
          context.pop();
        },
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
                          widget.imageFile,
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
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _MacroRow(
                            label: 'Nama Makanan',
                            value: widget.userFoodName.isEmpty
                                ? '-'
                                : widget.userFoodName,
                          ),
                          _MacroRow(
                            label: 'Deskripsi',
                            value: widget.userDescription.isEmpty
                                ? '-'
                                : widget.userDescription,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FoodMacroAnalysisCard(analysis: widget.analysis),
                    if (_saveError != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _saveError!,
                          style: const TextStyle(
                            color: Color(0xFFB91C1C),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
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
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(
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
                        onPressed: _isSaving ? null : _handleUseResult,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                widget.onSaveConsumption == null
                                    ? 'Pakai Hasil'
                                    : 'Pakai Hasil dan Simpan',
                                style: const TextStyle(
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
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
