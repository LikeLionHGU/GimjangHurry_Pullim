/// tool_assets.dart
///
/// 도구(tool) 에셋.
/// 인덱스(1~13)로 조회한다.
///
///   final tool = kTools[7]!;            // 라크로스볼
///   final balls = toolsByCategory(ToolCategory.massageBall);
library tool_assets;

/// 도구 대분류.
enum ToolCategory {
  foamRoller('폼롤러'),
  massageBall('마사지볼'),
  stick('스틱');

  const ToolCategory(this.label);
  final String label;
}

/// 도구 형태.
enum ToolShape {
  smooth('스무스'),
  grid('그리드'),
  bumpy('돌기형'),
  half('하프'),
  mini('미니'),
  psoasTool('장요근툴'),
  lacrosse('라크로스'),
  spiky('스파이키'),
  cork('코르크'),
  tennis('테니스'),
  peanut('피넛볼'),
  rollerStick('롤러스틱'),
  triggerBar('지압바');

  const ToolShape(this.label);
  final String label;
}

/// 도구 한 개.
class Tool {
  const Tool({
    required this.index,
    required this.category,
    required this.shape,
  });

  /// 조회용 인덱스.
  final int index;

  /// 폼롤러 / 마사지볼 / 스틱.
  final ToolCategory category;

  /// 스무스 / 그리드 / 피넛볼 등.
  final ToolShape shape;

  /// 예: "피넛볼 폼롤러"가 아닌 "피넛볼 마사지볼" 형태의 표시용 이름.
  String get displayName => '${shape.label} ${category.label}';
}

/// 인덱스 → 도구.
const Map<int, Tool> kTools = <int, Tool>{
  1: Tool(
    index: 1,
    category: ToolCategory.foamRoller,
    shape: ToolShape.smooth,
  ),
  2: Tool(
    index: 2,
    category: ToolCategory.foamRoller,
    shape: ToolShape.grid,
  ),
  3: Tool(
    index: 3,
    category: ToolCategory.foamRoller,
    shape: ToolShape.bumpy,
  ),
  4: Tool(
    index: 4,
    category: ToolCategory.foamRoller,
    shape: ToolShape.half,
  ),
  5: Tool(
    index: 5,
    category: ToolCategory.foamRoller,
    shape: ToolShape.mini,
  ),
  6: Tool(
    index: 6,
    category: ToolCategory.massageBall,
    shape: ToolShape.psoasTool,
  ),
  7: Tool(
    index: 7,
    category: ToolCategory.massageBall,
    shape: ToolShape.lacrosse,
  ),
  8: Tool(
    index: 8,
    category: ToolCategory.massageBall,
    shape: ToolShape.spiky,
  ),
  9: Tool(
    index: 9,
    category: ToolCategory.massageBall,
    shape: ToolShape.cork,
  ),
  10: Tool(
    index: 10,
    category: ToolCategory.massageBall,
    shape: ToolShape.tennis,
  ),
  11: Tool(
    index: 11,
    category: ToolCategory.massageBall,
    shape: ToolShape.peanut,
  ),
  12: Tool(
    index: 12,
    category: ToolCategory.stick,
    shape: ToolShape.rollerStick,
  ),
  13: Tool(
    index: 13,
    category: ToolCategory.stick,
    shape: ToolShape.triggerBar,
  ),
};

/// 인덱스로 단건 조회.
Tool? toolOf(int index) => kTools[index];

/// 인덱스 목록으로 다건 조회. 없는 인덱스는 건너뛴다.
List<Tool> toolsOf(Iterable<int> indexes) =>
    indexes.map((i) => kTools[i]).whereType<Tool>().toList(growable: false);

/// 카테고리로 필터.
List<Tool> toolsByCategory(ToolCategory category) => kTools.values
    .where((t) => t.category == category)
    .toList(growable: false);
