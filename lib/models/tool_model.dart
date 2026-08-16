/// 도구 카테고리
enum ToolCategory { foamRoller, massageBall }

/// 도구 형태
enum ToolShape {
  // 폼롤러
  normal, // 일반
  soft, // 소프트
  hard, // 하드
  grid, // 돌기형/그리드
  half, // 하프
  mini, // 미니

  // 마사지볼
  single, // 싱글
  peanut, // 피넛/더블볼
  softBall, // 소프트
  hardBall, // 하드
  miniBall, // 미니
}

class ToolModel {
  final int? toolId;
  final ToolCategory category;
  final ToolShape shape;
  final String? img;

  ToolModel({
    this.toolId,
    required this.category,
    required this.shape,
    this.img,
  });

  String get categoryName {
    switch (category) {
      case ToolCategory.foamRoller:
        return '폼롤러';
      case ToolCategory.massageBall:
        return '마사지볼';
    }
  }

  String get shapeName {
    switch (shape) {
      case ToolShape.normal:
        return '일반';
      case ToolShape.soft:
        return '소프트';
      case ToolShape.hard:
        return '하드';
      case ToolShape.grid:
        return '돌기형';
      case ToolShape.half:
        return '하프';
      case ToolShape.mini:
        return '미니';
      case ToolShape.single:
        return '싱글';
      case ToolShape.peanut:
        return '피넛/더블볼';
      case ToolShape.softBall:
        return '소프트';
      case ToolShape.hardBall:
        return '하드';
      case ToolShape.miniBall:
        return '미니';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'tool_id': toolId,
      'category': category.name,
      'shape': shape.name,
      'img': img,
    };
  }

  factory ToolModel.fromMap(Map<String, dynamic> map) {
    return ToolModel(
      toolId: map['tool_id'] as int?,
      category: ToolCategory.values.firstWhere(
        (e) => e.name == map['category'],
      ),
      shape: ToolShape.values.firstWhere((e) => e.name == map['shape']),
      img: map['img'] as String?,
    );
  }
}

/// 사용자 보유 도구
class OwnedTool {
  final int? id;
  final int userId;
  final int toolId;

  OwnedTool({this.id, required this.userId, required this.toolId});

  Map<String, dynamic> toMap() {
    return {'tool_id': toolId, 'user_id': userId};
  }

  factory OwnedTool.fromMap(Map<String, dynamic> map) {
    return OwnedTool(
      id: map['tool_id'] as int?,
      userId: map['user_id'] as int,
      toolId: map['tool_id'] as int,
    );
  }
}
