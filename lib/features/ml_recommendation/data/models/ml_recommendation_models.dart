import 'dart:convert';

import 'package:pulsewise/features/diary/data/models/diary_models.dart';

class MlRecommendationLifestyle {
  final String variable;
  final String codeValue;
  final String comparison;
  final String description;
  final String changeStatus;
  final dynamic currentValue;
  final String recommendedValueInterval;

  MlRecommendationLifestyle({
    required this.variable,
    required this.codeValue,
    required this.comparison,
    required this.description,
    required this.changeStatus,
    required this.currentValue,
    required this.recommendedValueInterval,
  });

  factory MlRecommendationLifestyle.fromJson(Map<String, dynamic> json) {
    return MlRecommendationLifestyle(
      variable: json['variable']?.toString() ?? '',
      codeValue: json['codeValue']?.toString() ?? '',
      comparison: json['comparison']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      changeStatus: json['changeStatus']?.toString() ?? '',
      currentValue: json['currentValue'],
      recommendedValueInterval:
          json['recommendedValueInterval']?.toString() ?? '',
    );
  }
}

class MlRecommendationResult {
  final List<MlRecommendationLifestyle> lifestyle;
  final String timeTaken;
  final double currentRisk;
  final double riskReduction;
  final String timeGenerated;
  final double currentRiskThresh;
  final double riskReductionThresh;
  final double riskAfterRecommendation;
  final double riskAfterRecommendationThresh;

  MlRecommendationResult({
    required this.lifestyle,
    required this.timeTaken,
    required this.currentRisk,
    required this.riskReduction,
    required this.timeGenerated,
    required this.currentRiskThresh,
    required this.riskReductionThresh,
    required this.riskAfterRecommendation,
    required this.riskAfterRecommendationThresh,
  });

  factory MlRecommendationResult.fromJson(Map<String, dynamic> json) {
    var lifestyleList = <MlRecommendationLifestyle>[];
    if (json['lifestyle'] != null) {
      for (final item in json['lifestyle']) {
        if (item is Map<String, dynamic>) {
          lifestyleList.add(MlRecommendationLifestyle.fromJson(item));
        }
      }
    }
    return MlRecommendationResult(
      lifestyle: lifestyleList,
      timeTaken: json['timeTaken']?.toString() ?? '',
      currentRisk:
          double.tryParse(json['currentRisk']?.toString() ?? '0') ?? 0.0,
      riskReduction:
          double.tryParse(json['riskReduction']?.toString() ?? '0') ?? 0.0,
      timeGenerated: json['timeGenerated']?.toString() ?? '',
      currentRiskThresh:
          double.tryParse(json['currentRiskThresh']?.toString() ?? '0') ?? 0.0,
      riskReductionThresh:
          double.tryParse(json['riskReductionThresh']?.toString() ?? '0') ??
              0.0,
      riskAfterRecommendation:
          double.tryParse(json['riskAfterRecommendation']?.toString() ?? '0') ??
              0.0,
      riskAfterRecommendationThresh: double.tryParse(
              json['riskAfterRecommendationThresh']?.toString() ?? '0') ??
          0.0,
    );
  }
}

class MlRecommendationBody {
  final int status;
  final List<double> resultHistory;
  final String statusMessage;
  final MlRecommendationResult recommendationResult;

  MlRecommendationBody({
    required this.status,
    required this.resultHistory,
    required this.statusMessage,
    required this.recommendationResult,
  });

  factory MlRecommendationBody.fromJson(Map<String, dynamic> json) {
    var history = <double>[];
    if (json['resultHistory'] != null) {
      for (final item in json['resultHistory']) {
        history.add(double.tryParse(item.toString()) ?? 0.0);
      }
    }
    return MlRecommendationBody(
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      resultHistory: history,
      statusMessage: json['statusMessage']?.toString() ?? '',
      recommendationResult: json['recommendationResult'] != null
          ? MlRecommendationResult.fromJson(
              Map<String, dynamic>.from(json['recommendationResult']))
          : MlRecommendationResult(
              lifestyle: const [],
              timeTaken: '',
              currentRisk: 0.0,
              riskReduction: 0.0,
              timeGenerated: '',
              currentRiskThresh: 0.0,
              riskReductionThresh: 0.0,
              riskAfterRecommendation: 0.0,
              riskAfterRecommendationThresh: 0.0,
            ),
    );
  }
}

class MlRecommendationUpstream {
  final String endpoint;
  final int status;
  final MlRecommendationBody? body;

  MlRecommendationUpstream({
    required this.endpoint,
    required this.status,
    this.body,
  });

  factory MlRecommendationUpstream.fromJson(Map<String, dynamic> json) {
    MlRecommendationBody? parsedBody;
    var rawBody = json['body'];
    if (rawBody is String) {
      try {
        rawBody = jsonDecode(rawBody);
      } catch (_) {}
    }
    if (rawBody is Map<String, dynamic>) {
      parsedBody = MlRecommendationBody.fromJson(rawBody);
    }

    return MlRecommendationUpstream(
      endpoint: json['endpoint']?.toString() ?? '',
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      body: parsedBody,
    );
  }
}

class MlRecommendationData {
  final String resultId;
  final String patientId;
  final String requestedByUserId;
  final String inferenceType;
  final String requestContext;
  final String mlVersion;
  final String payloadHash;
  final MlRecommendationUpstream? upstream;
  final String generatedAt;
  final String createdAt;

  MlRecommendationData({
    required this.resultId,
    required this.patientId,
    required this.requestedByUserId,
    required this.inferenceType,
    required this.requestContext,
    required this.mlVersion,
    required this.payloadHash,
    this.upstream,
    required this.generatedAt,
    required this.createdAt,
  });

  factory MlRecommendationData.fromJson(Map<String, dynamic> json) {
    return MlRecommendationData(
      resultId: json['resultId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      requestedByUserId: json['requestedByUserId']?.toString() ?? '',
      inferenceType: json['inferenceType']?.toString() ?? '',
      requestContext: json['requestContext']?.toString() ?? '',
      mlVersion: json['mlVersion']?.toString() ?? '',
      payloadHash: json['payloadHash']?.toString() ?? '',
      upstream: json['upstream'] != null
          ? MlRecommendationUpstream.fromJson(
              Map<String, dynamic>.from(json['upstream']))
          : null,
      generatedAt: json['generatedAt']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class MlRecommendationResponse {
  final bool success;
  final String message;
  final MlRecommendationData? data;

  MlRecommendationResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory MlRecommendationResponse.fromJson(Map<String, dynamic> json) {
    return MlRecommendationResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null
          ? MlRecommendationData.fromJson(
              Map<String, dynamic>.from(json['data']))
          : null,
    );
  }
}

class MlRecommendationHistoryResponse {
  final List<MlRecommendationHistoryItem> items;
  final DiaryHistoryPagination pagination;

  const MlRecommendationHistoryResponse({
    required this.items,
    required this.pagination,
  });

  factory MlRecommendationHistoryResponse.fromJson(Map<String, dynamic> json) {
    return MlRecommendationHistoryResponse(
      items: ((json['items'] as List?) ?? const [])
          .map((item) => MlRecommendationHistoryItem.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      pagination: DiaryHistoryPagination.fromJson(
        (json['pagination'] as Map<String, dynamic>?) ?? const {},
      ),
    );
  }
}

class MlRecommendationHistoryItem {
  final String resultId;
  final String inferenceType;
  final String requestContext;
  final String mlVersion;
  final String generatedAt;

  MlRecommendationHistoryItem({
    required this.resultId,
    required this.inferenceType,
    required this.requestContext,
    required this.mlVersion,
    required this.generatedAt,
  });

  factory MlRecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    return MlRecommendationHistoryItem(
      resultId: json['resultId']?.toString() ?? '',
      inferenceType: json['inferenceType']?.toString() ?? '',
      requestContext: json['requestContext']?.toString() ?? '',
      mlVersion: json['mlVersion']?.toString() ?? '',
      generatedAt: json['generatedAt']?.toString() ?? '',
    );
  }
}
