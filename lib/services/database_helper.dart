import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/tool_model.dart';
import '../models/course_model.dart';
import '../models/step_model.dart';
import '../models/move_model.dart';
import '../models/posture_result_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fascia_release.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // USER 테이블
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // TOOL 테이블 (사전 정의 도구 목록)
    await db.execute('''
      CREATE TABLE tools (
        tool_id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        shape TEXT NOT NULL,
        img TEXT
      )
    ''');

    // OWNED_TOOL 테이블 (사용자 보유 도구)
    await db.execute('''
      CREATE TABLE owned_tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (tool_id) REFERENCES tools(tool_id),
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      )
    ''');

    // COURSE 테이블
    await db.execute('''
      CREATE TABLE courses (
        course_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_time INTEGER NOT NULL,
        total_move INTEGER NOT NULL,
        save INTEGER NOT NULL DEFAULT 0,
        executed_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        progress INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // STEP 테이블
    await db.execute('''
      CREATE TABLE steps (
        used_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        move_id INTEGER NOT NULL,
        tool_id INTEGER NOT NULL,
        order_num INTEGER NOT NULL,
        before_fatigue INTEGER NOT NULL DEFAULT 5,
        after_fatigue INTEGER NOT NULL DEFAULT 5,
        reason TEXT,
        time INTEGER NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
      )
    ''');

    // MOVE 테이블 (동작 에셋)
    await db.execute('''
      CREATE TABLE moves (
        move_id INTEGER PRIMARY KEY AUTOINCREMENT,
        body TEXT NOT NULL,
        tool TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        img TEXT,
        time INTEGER NOT NULL
      )
    ''');

    // POSTURE_RESULT 테이블 (자세 측정 결과)
    await db.execute('''
      CREATE TABLE posture_results (
        result_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        measured_at TEXT NOT NULL,
        angles TEXT,
        issues TEXT,
        summary TEXT,
        score INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(user_id)
      )
    ''');

    // 기본 도구 데이터 삽입
    await _insertDefaultTools(db);
    // 기본 동작 데이터 삽입
    await _insertDefaultMoves(db);
  }

  Future<void> _insertDefaultTools(Database db) async {
    final tools = [
      // 폼롤러
      {'category': 'foamRoller', 'shape': 'normal', 'img': null},
      {'category': 'foamRoller', 'shape': 'soft', 'img': null},
      {'category': 'foamRoller', 'shape': 'hard', 'img': null},
      {'category': 'foamRoller', 'shape': 'grid', 'img': null},
      {'category': 'foamRoller', 'shape': 'half', 'img': null},
      {'category': 'foamRoller', 'shape': 'mini', 'img': null},
      // 마사지볼
      {'category': 'massageBall', 'shape': 'single', 'img': null},
      {'category': 'massageBall', 'shape': 'peanut', 'img': null},
      {'category': 'massageBall', 'shape': 'softBall', 'img': null},
      {'category': 'massageBall', 'shape': 'hardBall', 'img': null},
      {'category': 'massageBall', 'shape': 'miniBall', 'img': null},
    ];

    for (final tool in tools) {
      await db.insert('tools', tool);
    }
  }

  Future<void> _insertDefaultMoves(Database db) async {
    final moves = [
      {
        'body': '종아리',
        'tool': '폼롤러',
        'name': '종아리 롤링',
        'description': '폼롤러를 종아리 아래에 위치합니다\n손으로 바닥을 짚고 몸을 지탱합니다.\n천천히 앞뒤로 움직이며 근육을 이완합니다.\n통증이 느껴지면 그 위치에서 10~15초 유지합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '허벅지',
        'tool': '폼롤러',
        'name': '허벅지 전면 롤링',
        'description': '엎드린 자세에서 폼롤러를 허벅지 앞쪽에 놓습니다.\n팔꿈치로 몸을 지탱하며 앞뒤로 움직입니다.\n무릎 위부터 골반 아래까지 천천히 이동합니다.\n통증 부위에서 잠시 멈추어 압박합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '허벅지 뒤',
        'tool': '폼롤러',
        'name': '햄스트링 롤링',
        'description': '앉은 자세에서 폼롤러를 허벅지 뒤에 놓습니다.\n손으로 몸을 지탱하며 앞뒤로 움직입니다.\n엉덩이부터 무릎 뒤까지 천천히 이동합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '등',
        'tool': '폼롤러',
        'name': '등 상부 롤링',
        'description': '등 상부에 폼롤러를 놓고 누운 자세를 취합니다.\n무릎을 구부리고 발을 바닥에 댑니다.\n엉덩이를 들어 천천히 위아래로 움직입니다.\n목까지 올라가지 않도록 주의합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '둔근',
        'tool': '마사지볼',
        'name': '둔근 압박',
        'description': '마사지볼 위에 엉덩이를 올려놓습니다.\n한쪽 다리를 반대쪽 무릎 위에 올립니다.\n체중을 이용해 천천히 압박합니다.\n통증 부위에서 10~15초 유지합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '발',
        'tool': '마사지볼',
        'name': '족저 압박',
        'description': '서있는 자세에서 마사지볼을 발바닥 아래에 놓습니다.\n체중을 실어 천천히 앞뒤로 굴립니다.\n아치 부분을 집중적으로 압박합니다.\n통증이 심하면 의자에 앉아서 진행합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '어깨',
        'tool': '마사지볼',
        'name': '어깨 압박',
        'description': '벽에 마사지볼을 대고 어깨 뒷면에 위치시킵니다.\n몸무게를 이용해 적당한 압력을 가합니다.\n작은 원을 그리며 근육을 이완합니다.\n승모근 부위를 집중적으로 풀어줍니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '목',
        'tool': '마사지볼',
        'name': '목 뒤 압박',
        'description': '바닥에 누운 상태에서 마사지볼을 목 뒤에 놓습니다.\n천천히 고개를 좌우로 돌려 근육을 이완합니다.\n뒷목 중앙에서 양 옆으로 이동하며 압박합니다.\n과도한 압력을 가하지 않도록 주의합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '허리',
        'tool': '폼롤러',
        'name': '허리 롤링',
        'description': '폼롤러를 허리 아래에 놓고 누운 자세를 취합니다.\n무릎을 구부리고 코어에 힘을 줍니다.\n좌우로 부드럽게 움직이며 이완합니다.\n척추 직접 압박은 피합니다.',
        'img': null,
        'time': 60,
      },
      {
        'body': '가슴',
        'tool': '마사지볼',
        'name': '가슴 압박',
        'description': '벽에 마사지볼을 대고 가슴 근육에 위치시킵니다.\n팔을 천천히 위아래로 움직이며 이완합니다.\n쇄골 아래쪽을 집중적으로 풀어줍니다.',
        'img': null,
        'time': 60,
      },
    ];

    for (final move in moves) {
      await db.insert('moves', move);
    }
  }

  // ==================== USER ====================

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap()..remove('user_id'));
  }

  Future<UserModel?> getUser(int userId) async {
    final db = await database;
    final maps = await db.query('users', where: 'user_id = ?', whereArgs: [userId]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // ==================== TOOLS ====================

  Future<List<ToolModel>> getAllTools() async {
    final db = await database;
    final maps = await db.query('tools');
    return maps.map((m) => ToolModel.fromMap(m)).toList();
  }

  Future<List<ToolModel>> getToolsByCategory(ToolCategory category) async {
    final db = await database;
    final maps = await db.query(
      'tools',
      where: 'category = ?',
      whereArgs: [category.name],
    );
    return maps.map((m) => ToolModel.fromMap(m)).toList();
  }

  Future<ToolModel?> getTool(int toolId) async {
    final db = await database;
    final maps = await db.query('tools', where: 'tool_id = ?', whereArgs: [toolId]);
    if (maps.isEmpty) return null;
    return ToolModel.fromMap(maps.first);
  }

  // ==================== OWNED TOOLS ====================

  Future<int> addOwnedTool(int userId, int toolId) async {
    final db = await database;
    return await db.insert('owned_tools', {
      'user_id': userId,
      'tool_id': toolId,
    });
  }

  Future<int> removeOwnedTool(int userId, int toolId) async {
    final db = await database;
    return await db.delete(
      'owned_tools',
      where: 'user_id = ? AND tool_id = ?',
      whereArgs: [userId, toolId],
    );
  }

  Future<List<ToolModel>> getOwnedTools(int userId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM tools t
      INNER JOIN owned_tools ot ON t.tool_id = ot.tool_id
      WHERE ot.user_id = ?
    ''', [userId]);
    return maps.map((m) => ToolModel.fromMap(m)).toList();
  }

  Future<bool> isToolOwned(int userId, int toolId) async {
    final db = await database;
    final maps = await db.query(
      'owned_tools',
      where: 'user_id = ? AND tool_id = ?',
      whereArgs: [userId, toolId],
    );
    return maps.isNotEmpty;
  }

  // ==================== COURSES ====================

  Future<int> insertCourse(CourseModel course) async {
    final db = await database;
    return await db.insert('courses', course.toMap()..remove('course_id'));
  }

  Future<List<CourseModel>> getSavedCourses() async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'save = 1',
      orderBy: 'executed_at DESC',
    );
    return maps.map((m) => CourseModel.fromMap(m)).toList();
  }

  Future<List<CourseModel>> getCompletedCourses() async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: "status = 'completed'",
      orderBy: 'executed_at DESC',
    );
    return maps.map((m) => CourseModel.fromMap(m)).toList();
  }

  Future<List<CourseModel>> getRecentCourses({int limit = 3}) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: "status = 'completed'",
      orderBy: 'executed_at DESC',
      limit: limit,
    );
    return maps.map((m) => CourseModel.fromMap(m)).toList();
  }

  Future<int> updateCourse(CourseModel course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'course_id = ?',
      whereArgs: [course.courseId],
    );
  }

  Future<int> deleteCourse(int courseId) async {
    final db = await database;
    await db.delete('steps', where: 'course_id = ?', whereArgs: [courseId]);
    return await db.delete('courses', where: 'course_id = ?', whereArgs: [courseId]);
  }

  // ==================== STEPS ====================

  Future<int> insertStep(StepModel step) async {
    final db = await database;
    return await db.insert('steps', step.toMap()..remove('used_id'));
  }

  Future<List<StepModel>> getStepsByCourse(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'steps',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'order_num ASC',
    );
    return maps.map((m) => StepModel.fromMap(m)).toList();
  }

  Future<int> updateStep(StepModel step) async {
    final db = await database;
    return await db.update(
      'steps',
      step.toMap(),
      where: 'used_id = ?',
      whereArgs: [step.usedId],
    );
  }

  // ==================== MOVES ====================

  Future<List<MoveModel>> getAllMoves() async {
    final db = await database;
    final maps = await db.query('moves');
    return maps.map((m) => MoveModel.fromMap(m)).toList();
  }

  Future<MoveModel?> getMove(int moveId) async {
    final db = await database;
    final maps = await db.query('moves', where: 'move_id = ?', whereArgs: [moveId]);
    if (maps.isEmpty) return null;
    return MoveModel.fromMap(maps.first);
  }

  Future<List<MoveModel>> getMovesByBody(String body) async {
    final db = await database;
    final maps = await db.query('moves', where: 'body = ?', whereArgs: [body]);
    return maps.map((m) => MoveModel.fromMap(m)).toList();
  }

  // ==================== POSTURE RESULTS ====================

  Future<int> insertPostureResult(PostureResultModel result) async {
    final db = await database;
    return await db.insert('posture_results', result.toMap()..remove('result_id'));
  }

  Future<List<PostureResultModel>> getPostureResults(int userId) async {
    final db = await database;
    final maps = await db.query(
      'posture_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measured_at DESC',
    );
    return maps.map((m) => PostureResultModel.fromMap(m)).toList();
  }

  Future<PostureResultModel?> getLatestPostureResult(int userId) async {
    final db = await database;
    final maps = await db.query(
      'posture_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'measured_at DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return PostureResultModel.fromMap(maps.first);
  }

  // ==================== STATISTICS (마이페이지용) ====================

  /// 총 실행 횟수
  Future<int> getTotalExecutions() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM courses WHERE status = 'completed'",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 완료율 (완료된 코스 / 전체 코스)
  Future<double> getCompletionRate() async {
    final db = await database;
    final total = await db.rawQuery('SELECT COUNT(*) as cnt FROM courses');
    final completed = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM courses WHERE status = 'completed'",
    );
    final totalCount = Sqflite.firstIntValue(total) ?? 0;
    final completedCount = Sqflite.firstIntValue(completed) ?? 0;
    if (totalCount == 0) return 0.0;
    return (completedCount / totalCount) * 100;
  }

  /// 평균 피로도 감소
  Future<double> getAverageFatigueReduction() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT AVG(before_fatigue - after_fatigue) as avg_reduction FROM steps WHERE after_fatigue > 0',
    );
    if (result.isEmpty || result.first['avg_reduction'] == null) return 0.0;
    return (result.first['avg_reduction'] as num).toDouble();
  }
}
