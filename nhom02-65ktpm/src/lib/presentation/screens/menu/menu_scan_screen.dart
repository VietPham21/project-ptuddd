import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../application/analyze_food_text.dart';
import '../../../application/analyze_menu_photo.dart';
import '../../../application/session_service.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/menu_strings.dart';
import '../../../core/strings/scan_strings.dart';
import '../../../data/ai/image_preparer.dart';
import '../../../domain/enums.dart';
import '../../widgets/ai_error_view.dart';
import '../../widgets/disclaimer_note.dart';
import '../../widgets/tip_card.dart';
import '../review/review_meal_screen.dart';

/// Gọi món thông minh: chụp thực đơn -> 2–3 đề xuất (tên món, cách gọi, lý do).
/// "Tôi đã gọi món này" -> AI đánh giá món đó -> màn hình xác nhận.
class MenuScanScreen extends StatefulWidget {
  const MenuScanScreen({super.key, this.source = ImageSource.camera});

  final ImageSource source;

  static Future<void> open(BuildContext context) => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const MenuScanScreen()));

  @override
  State<MenuScanScreen> createState() => _MenuScanScreenState();
}

class _MenuScanScreenState extends State<MenuScanScreen> {
  final _preparer = sl<ImagePreparer>();
  final _analyzeMenu = sl<AnalyzeMenuPhoto>();
  final _analyzeText = sl<AnalyzeFoodText>();
  final _session = sl<SessionService>();

  Uint8List? _image;
  bool _analyzing = false;
  AppFailure? _failure;
  List<MenuSuggestion>? _suggestions;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickAndAnalyze(widget.source));
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final bytes = await _preparer.pick(source);
    if (!mounted) return;
    if (bytes == null) {
      if (_image == null) Navigator.of(context).pop();
      return;
    }
    setState(() => _image = bytes);
    await _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final image = _image;
    if (image == null) return;
    setState(() {
      _analyzing = true;
      _failure = null;
      _suggestions = null;
    });
    final result = await _analyzeMenu(image);
    if (!mounted) return;
    setState(() {
      _analyzing = false;
      switch (result) {
        case Ok(:final value):
          _suggestions = value;
        case Err(:final failure):
          _failure = failure;
      }
    });
  }

  /// Người dùng đã gọi món -> nhờ AI đánh giá mức độ món đó (chỉ văn bản),
  /// rồi chuyển sang màn hình xác nhận. AI lỗi -> tự chọn mức độ.
  Future<void> _ordered(MenuSuggestion suggestion) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text(MenuStrings.preparing)),
          ],
        ),
      ),
    );
    final description = suggestion.howToOrder.isEmpty
        ? suggestion.menuItemName
        : '${suggestion.menuItemName} (${suggestion.howToOrder})';
    final result = await _analyzeText(description);
    if (!mounted) return;
    Navigator.of(context).pop(); // đóng hộp thoại chờ
    switch (result) {
      case Ok(:final value):
        await ReviewMealScreen.open(
          context,
          items: [value.copyWith(name: suggestion.menuItemName)],
          inputMethod: InputMethod.menu,
          fromAi: true,
          replace: true,
        );
      case Err():
        await ReviewMealScreen.openManual(
          context,
          name: suggestion.menuItemName,
          inputMethod: InputMethod.menu,
          replace: true,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(MenuStrings.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 160,
                child: Image.memory(_image!, fit: BoxFit.cover, width: double.infinity),
              ),
            ),
          const SizedBox(height: 16),
          if (_analyzing) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
            Text(MenuStrings.analyzing,
                textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          ],
          if (_failure != null)
            AiErrorView(
              failure: _failure!,
              onManual: () => ReviewMealScreen.openManual(
                context,
                inputMethod: InputMethod.menu,
                replace: true,
              ),
              onRetry: _failure!.type == FailureType.notRecognized
                  ? () => _pickAndAnalyze(ImageSource.camera)
                  : _runAnalysis,
              retryLabel: _failure!.type == FailureType.notRecognized
                  ? MenuStrings.scanAnother
                  : AppStrings.retry,
            ),
          if (_suggestions != null) ...[
            Text(
              MenuStrings.resultHeader(AppStrings.goal(_session.goal)),
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (final s in _suggestions!) _SuggestionCard(suggestion: s, onOrdered: _ordered),
            const SizedBox(height: 8),
            const DisclaimerNote(full: true),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _pickAndAnalyze(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text(MenuStrings.scanAnother),
            ),
          ],
          const SizedBox(height: 12),
          Text(ScanStrings.privacyNote,
              textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.suggestion, required this.onOrdered});

  final MenuSuggestion suggestion;
  final ValueChanged<MenuSuggestion> onOrdered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              suggestion.menuItemName,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (suggestion.howToOrder.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.record_voice_over_outlined, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                        text: '${MenuStrings.howToOrder}: ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: suggestion.howToOrder),
                    ])),
                  ),
                ],
              ),
            ],
            if (suggestion.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(MenuStrings.why, style: theme.textTheme.labelLarge),
              for (final tip in suggestion.reasons) TipCard(tip: tip),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => onOrdered(suggestion),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(MenuStrings.iOrderedThis),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
