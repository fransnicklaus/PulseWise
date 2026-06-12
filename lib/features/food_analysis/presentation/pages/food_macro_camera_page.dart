import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulsewise/core/utils/app_toast.dart';
import 'package:pulsewise/core/widgets/custom_app_bar.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_consumption_result.dart';
import 'package:pulsewise/features/food_analysis/data/models/food_macro_analysis.dart';
import 'package:pulsewise/features/food_analysis/presentation/providers/food_nutrition_estimate_api_provider.dart';

typedef SubmitFoodMacroCaptureCallback = Future<void> Function(
  FoodMacroCaptureResult result,
);

class FoodMacroCameraPage extends ConsumerStatefulWidget {
  const FoodMacroCameraPage({
    super.key,
    this.onUseAnalysis,
  });

  final SubmitFoodMacroCaptureCallback? onUseAnalysis;

  @override
  ConsumerState<FoodMacroCameraPage> createState() =>
      _FoodMacroCameraPageState();
}

class _FoodMacroCameraPageState extends ConsumerState<FoodMacroCameraPage> {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];
  bool _isCameraLoading = true;
  bool _isSelectingImage = false;
  String? _errorMessage;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
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
    if (_availableCameras.length < 2 || _isCameraLoading || _isSelectingImage) {
      return;
    }

    final nextIndex = (_cameraIndex + 1) % _availableCameras.length;
    await _initializeCamera(index: nextIndex);
  }

  Future<void> _openImageReviewPage(_SelectedFoodImage imageData) async {
    try {
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => _FoodMacroImageReviewPage(
            imageData: imageData,
            onUseAnalysis: widget.onUseAnalysis,
          ),
        ),
      );

      if (!mounted || result == null) return;

      final action = (result['action'] ?? '').toString();
      if (action == 'saved') {
        Navigator.of(context).pop(const {'action': 'saved'});
        return;
      }
      if (action == 'use') {
        Navigator.of(context).pop(result);
        return;
      }
      if (action.isEmpty && result.containsKey('analysis')) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      AppToast.warning(context, 'Kamera belum siap.');
      return;
    }
    if (_isSelectingImage) return;

    setState(() {
      _isSelectingImage = true;
      _errorMessage = null;
    });

    try {
      final photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      if (!mounted) return;

      await _openImageReviewPage(
        _SelectedFoodImage(
          bytes: bytes,
          mimeType: 'image/jpeg',
          fileName: _fileNameFromPath(photo.path) ?? 'captured_food.jpg',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isSelectingImage) return;

    setState(() {
      _isSelectingImage = true;
      _errorMessage = null;
    });

    try {
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

      final imageBytes = selected.bytes;
      if (imageBytes == null || imageBytes.isEmpty) {
        if (!mounted) return;
        AppToast.warning(
          context,
          'File gambar tidak bisa dibaca di perangkat ini. Coba pilih gambar lain.',
        );
        return;
      }

      await _openImageReviewPage(
        _SelectedFoodImage(
          bytes: imageBytes,
          mimeType: _guessMimeType(
            selected.name.isNotEmpty ? selected.name : selected.path,
          ),
          fileName:
              selected.name.isNotEmpty ? selected.name : 'food_gallery.jpg',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSelectingImage = false;
        });
      }
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

  String _guessMimeType(String? filePathOrName) {
    final source = (filePathOrName ?? '').trim().toLowerCase();
    final dotIndex = source.lastIndexOf('.');
    final extension = dotIndex >= 0 ? source.substring(dotIndex) : '';

    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  String? _fileNameFromPath(String? path) {
    final normalizedPath = (path ?? '').trim();
    if (normalizedPath.isEmpty) return null;

    final separators = RegExp(r'[\\/]');
    final segments = normalizedPath.split(separators);
    for (final segment in segments.reversed) {
      final trimmed = segment.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;
    final hasPreview = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
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
                    height: 1.4,
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
                  Color(0xCC000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _isSelectingImage
                            ? null
                            : () => Navigator.of(context).pop(),
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
                            backgroundColor: Colors.black.withOpacity(0.35),
                          ),
                          icon: const Icon(
                            Icons.cameraswitch_rounded,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  if (hasPreview)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 152),
                      child: IgnorePointer(
                        ignoring: _isSelectingImage,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isSelectingImage ? 0.55 : 1,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _capturePhoto,
                                  customBorder: const CircleBorder(),
                                  child: Ink(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      color: Colors.white.withOpacity(0.18),
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Ambil Foto',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isSelectingImage ? null : _pickFromGallery,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text(
                          'Pilih dari Galeri',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB91C1C),
                          height: 1.4,
                        ),
                      ),
                    ] else if (!hasPreview) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Kamera belum tersedia, tapi Anda tetap bisa pilih gambar dari galeri.',
                        textAlign: TextAlign.center,
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
          if (_isSelectingImage)
            Container(
              color: Colors.black.withOpacity(0.28),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SelectedFoodImage {
  const _SelectedFoodImage({
    required this.bytes,
    required this.mimeType,
    required this.fileName,
  });

  final Uint8List bytes;
  final String mimeType;
  final String fileName;
}

class _FoodMacroImageReviewPage extends ConsumerStatefulWidget {
  const _FoodMacroImageReviewPage({
    required this.imageData,
    this.onUseAnalysis,
  });

  final _SelectedFoodImage imageData;
  final SubmitFoodMacroCaptureCallback? onUseAnalysis;

  @override
  ConsumerState<_FoodMacroImageReviewPage> createState() =>
      _FoodMacroImageReviewPageState();
}

class _FoodMacroImageReviewPageState
    extends ConsumerState<_FoodMacroImageReviewPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _foodDescriptionController =
      TextEditingController();

  bool _isAnalyzing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _foodNameController.dispose();
    _foodDescriptionController.dispose();
    super.dispose();
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

  FoodMacroCaptureResult _buildCaptureResult(FoodMacroAnalysis analysis) {
    return FoodMacroCaptureResult(
      analysis: analysis,
      userFoodName: _foodNameController.text.trim(),
      userDescription: _foodDescriptionController.text.trim(),
    );
  }

  Future<void> _openAnalysisResultPage(FoodMacroAnalysis analysis) async {
    final captureResult = _buildCaptureResult(analysis);
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => _FoodMacroAnalysisResultPage(
          imageData: widget.imageData,
          analysis: analysis,
          userFoodName: captureResult.userFoodName,
          userDescription: captureResult.userDescription,
          onUseAnalysis: widget.onUseAnalysis == null
              ? null
              : () => widget.onUseAnalysis!(captureResult),
        ),
      ),
    );

    if (!mounted || result == null) return;

    final action = (result['action'] ?? '').toString();
    if (action == 'saved') {
      Navigator.of(context).pop(const {'action': 'saved'});
      return;
    }
    if (action == 'use') {
      Navigator.of(context).pop({
        'action': 'use',
        ...captureResult.toMap(),
      });
      return;
    }
    if (action == 'retake') {
      Navigator.of(context).pop(const {'action': 'retake'});
    }
  }

  Future<void> _analyzeImage() async {
    if (!_validateMealName() || _isAnalyzing) return;

    try {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = null;
      });

      final result =
          await ref.read(foodNutritionEstimateApiProvider).estimateNutrition(
                imageBytes: widget.imageData.bytes,
                mealName: _foodNameController.text.trim(),
                imageMimeType: widget.imageData.mimeType,
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

      await _openAnalysisResultPage(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Lengkapi Foto Makanan',
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
                        child: Image.memory(
                          widget.imageData.bytes,
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
                            decoration: _buildInputDecoration(
                              'Contoh: nasi padang, bakso, salad ayam',
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
                            decoration: _buildInputDecoration(
                              'Contoh: rendang, telur bulat, porsi besar, lebih banyak ayam',
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
                        ],
                      ),
                    ),
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
                        onPressed: _isAnalyzing
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
                          'Ambil Ulang',
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
                        onPressed: _isAnalyzing ? null : _analyzeImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE64060),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isAnalyzing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Analisis Foto',
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
    required this.imageData,
    required this.analysis,
    required this.userFoodName,
    required this.userDescription,
    this.onUseAnalysis,
  });

  final _SelectedFoodImage imageData;
  final FoodMacroAnalysis analysis;
  final String userFoodName;
  final String userDescription;

  final Future<void> Function()? onUseAnalysis;

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

    final onUseAnalysis = widget.onUseAnalysis;
    if (onUseAnalysis == null) {
      Navigator.of(context).pop(const {'action': 'use'});
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await onUseAnalysis();
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
                        child: Image.memory(
                          widget.imageData.bytes,
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
                                widget.onUseAnalysis == null
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
