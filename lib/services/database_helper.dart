import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/step_model.dart';
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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    // OWNED_TOOL 테이블 (사용자 보유 도구)
    // tool_id는 tool_assets의 인덱스(1~12)를 직접 참조한다.
    await db.execute('''
      CREATE TABLE owned_tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL
      )
    ''');

    // COURSE 테이블
    await db.execute('''
      CREATE TABLE courses (
        course_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_time INTEGER NOT NULL,
        total_move INTEGER NOT NULL,
        summary TEXT,
        before TEXT,
        after TEXT,
        save INTEGER NOT NULL DEFAULT 0,
        executed_at TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        progress INTEGER NOT NULL DEFAULT 0,
        source TEXT NOT NULL DEFAULT 'manual'
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
        reason TEXT,
        time INTEGER NOT NULL,
        FOREIGN KEY (course_id) REFERENCES courses(course_id)
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE courses ADD COLUMN source TEXT NOT NULL DEFAULT 'manual'",
      );
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

  Future<CourseModel?> getSavedCourseById(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  Future<void> updateCourseCompletion({
    required int courseId,
    required Map<String, int> after,
  }) async {
    final db = await database;
    await db.update(
      'courses',
      {
        'after': jsonEncode(after),
        'status': 'completed',
        'progress': 100,
        'executed_at': DateTime.now().toIso8601String(),
      },
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
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

  /// 평균 피로도 감소.
  /// courses 테이블의 before/after (JSON) 컬럼에서 부위별 피로도 차이의 평균을 계산한다.
  Future<double> getAverageFatigueReduction() async {
    final db = await database;
    final maps = await db.query(
      'courses',
      columns: ['before', 'after'],
      where: "status = 'completed' AND before IS NOT NULL AND after IS NOT NULL",
    );
    if (maps.isEmpty) return 0.0;

    int totalReduction = 0;
    int count = 0;
    for (final map in maps) {
      final beforeStr = map['before'] as String?;
      final afterStr = map['after'] as String?;
      if (beforeStr == null || afterStr == null) continue;
      final beforeMap = Map<String, dynamic>.from(jsonDecode(beforeStr) as Map);
      final afterMap = Map<String, dynamic>.from(jsonDecode(afterStr) as Map);
      for (final key in beforeMap.keys) {
        final b = (beforeMap[key] as num?)?.toInt() ?? 0;
        final a = (afterMap[key] as num?)?.toInt() ?? b;
        totalReduction += (b - a);
        count++;
      }
    }
    if (count == 0) return 0.0;
    return totalReduction / count;
  }
}
