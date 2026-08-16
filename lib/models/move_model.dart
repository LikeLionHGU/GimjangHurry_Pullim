/// 동작 모델 (ASSET: move 테이블)
class MoveModel {
  final int moveId;
  final String body; // 대상 부위
  final String tool; // 사용 도구
  final String name; // 동작 이름
  final String description; // 이완 방법 설명
  final String? img;
  final int time; // 기본 소요시간 (초)

  MoveModel({
    required this.moveId,
    required this.body,
    required this.tool,
    required this.name,
    required this.description,
    this.img,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'move_id': moveId,
      'body': body,
      'tool': tool,
      'name': name,
      'description': description,
      'img': img,
      'time': time,
    };
  }

  factory MoveModel.fromMap(Map<String, dynamic> map) {
    return MoveModel(
      moveId: map['move_id'] as int,
      body: map['body'] as String,
      tool: map['tool'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      img: map['img'] as String?,
      time: map['time'] as int,
    );
  }
}
