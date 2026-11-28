import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../core/strings/scan_strings.dart';
import '../../domain/entities/tip.dart';
import '../../domain/enums.dart';
import 'gemini_client.dart';
import 'parsers/menu_response_parser.dart';
import 'prompt_builder.dart';
import 'schemas.dart';

/// Gọi món thông minh: gửi ảnh thực đơn cho Gemini, nhận 0..3 đề xuất.
class MenuAnalysisService {
  MenuAnalysisService(this._client);

  final GeminiClient _client;

  Future<Result<ParsedMenuResponse>> analyzeMenuPhoto(
    Uint8List jpeg, {
    required Goal goal,
    required List<Tip> allowedTips,
  }) async {
    final raw = await _client.generateJson(
      systemInstruction: PromptBuilder.systemInstruction(goal: goal, allowedTips: allowedTips),
      schema: AiSchemas.menuAnalysis(allowedTips.map((t) => t.code).toList()),
      parts: [
        TextPart(PromptBuilder.menuPhotoPrompt()),
        InlineDataPart('image/jpeg', jpeg),
      ],
    );
    switch (raw) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        try {
          return Ok(MenuResponseParser.parse(value));
        } on FormatException catch (e) {
          debugPrint('AI menu JSON parse failed: $e');
          return Err(AppFailure(FailureType.invalidResponse, ScanStrings.invalidResponse, e));
        }
    }
  }
}
