/// 자세 측정 결과 모델
class PostureResultModel {
  final int? resultId;
  final int userId;
  final DateTime measuredAt;
  final Map<String, double> angles;
  final List<String> issues;
  final String? summary;
  final int score;
  final String? frontImagePath;
  final String? sideImagePath;

  PostureResultModel({
    this.resultId,
    required this.userId,
    DateTime? measuredAt,
    required this.angles,
    required this.issues,
    this.summary,
    this.score = 0,
    this.frontImagePath,
    this.sideImagePath,
  }) : measuredAt = measuredAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'result_id': resultId,
      'user_id': userId,
      'measured_at': measuredAt.toIso8601String(),
      'angles': angles.entries.map((e) => '${e.key}:${e.value}').join(','),
      'issues': issues.join(','),
      'summary': summary,
      'score': score,
      'front_image': frontImagePath,
      'side_image': sideImagePath,
    };
  }

  factory PostureResultModel.fromMap(Map<String, dynamic> map) {
    final anglesStr = map['angles'] as String? ?? '';
    final anglesMap = <String, double>{};
    if (anglesStr.isNotEmpty) {
      for (final entry in anglesStr.split(',')) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          anglesMap[parts[0]] = double.tryParse(parts[1]) ?? 0.0;
        }
      }
    }

    final issuesStr = map['issues'] as String? ?? '';
    final issuesList =
        issuesStr.isNotEmpty ? issuesStr.split(',') : <String>[];

    return PostureResultModel(
      resultId: map['result_id'] as int?,
      userId: map['user_id'] as int,
      measuredAt: DateTime.parse(map['measured_at'] as String),
      angles: anglesMap,
      issues: issuesList,
      summary: map['summary'] as String?,
      score: map['score'] as int? ?? 0,
      frontImagePath: map['front_image'] as String?,
      sideImagePath: map['side_image'] as String?,
    );
  }

  PostureResultModel copyWith({
    int? resultId,
    int? userId,
    DateTime? measuredAt,
    Map<String, double>? angles,
    List<String>? issues,
    String? summary,
    int? score,
    String? frontImagePath,
    String? sideImagePath,
  }) {
    return PostureResultModel(
      resultId: resultId ?? this.resultId,
      userId: userId ?? this.userId,
      measuredAt: measuredAt ?? this.measuredAt,
      angles: angles ?? this.angles,
      issues: issues ?? this.issues,
      summary: summary ?? this.summary,
      score: score ?? this.score,
      frontImagePath: frontImagePath ?? this.frontImagePath,
      sideImagePath: sideImagePath ?? this.sideImagePath,
    );
  }
}
