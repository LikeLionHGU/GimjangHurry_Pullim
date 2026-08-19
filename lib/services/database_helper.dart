import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/course_model.dart';
import '../models/step_model.dart';
import '../models/execution_model.dart';
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
      version: 3,
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
    await db.execute('''
      CREATE TABLE owned_tools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tool_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL
      )
    ''');

    // COURSE 테이블 — 코스 정체성만 저장
    await db.execute('''
      CREATE TABLE courses (
        course_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        total_time INTEGER NOT NULL,
        total_move INTEGER NOT NULL,
        summary TEXT,
        save INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
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

    // COURSE_EXECUTIONS 테이블 — 실행 기록
    await db.execute('''
      CREATE TABLE course_executions (
        execution_id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id INTEGER NOT NULL,
        executed_at TEXT NOT NULL,
        before_data TEXT,
        after_data TEXT,
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
        front_image TEXT,
        side_image TEXT,
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
    if (oldVersion < 3) {
      // course_executions 테이블 생성
      await db.execute('''
        CREATE TABLE IF NOT EXISTS course_executions (
          execution_id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER NOT NULL,
          executed_at TEXT NOT NULL,
          before_data TEXT,
          after_data TEXT,
          FOREIGN KEY (course_id) REFERENCES courses(course_id)
        )
      ''');

      // 기존 완료된 코스의 실행 데이터를 executions로 마이그레이션
      final completedCourses = await db.query(
        'courses',
        where: "status = 'completed' AND executed_at IS NOT NULL",
      );
      for (final row in completedCourses) {
        await db.insert('course_executions', {
          'course_id': row['course_id'],
          'executed_at': row['executed_at'],
          'before_data': row['before'],
          'after_data': row['after'],
        });
      }

      // 중복 코스 정리: 같은 이름+같은 스텝 구성의 코스들을 하나로 합침
      // 이름이 같은 completed 코스들을 그룹화
      final allCourses = await db.query('courses', orderBy: 'course_id ASC');
      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final c in allCourses) {
        final key = '${c['name']}_${c['total_time']}_${c['total_move']}';
        grouped.putIfAbsent(key, () => []).add(c);
      }

      for (final group in grouped.values) {
        if (group.length <= 1) continue;
        // 첫 번째를 대표 코스로 유지, 나머지 삭제
        final primary = group.first;
        final primaryId = primary['course_id'] as int;

        // 대표 코스가 저장 상태가 아닌데 그룹 내 저장된 게 있으면 대표에 반영
        final hasSaved = group.any((c) => (c['save'] as int) == 1);
        if (hasSaved) {
          await db.update(
            'courses',
            {'save': 1},
            where: 'course_id = ?',
            whereArgs: [primaryId],
          );
        }

        // 대표가 completed가 아닌데 그룹 내에 completed가 있으면 반영
        final hasCompleted = group.any((c) => c['status'] == 'completed');
        if (hasCompleted) {
          await db.update(
            'courses',
            {'status': 'completed'},
            where: 'course_id = ?',
            whereArgs: [primaryId],
          );
        }

        for (int i = 1; i < group.length; i++) {
          final dupId = group[i]['course_id'] as int;
          // executions의 course_id를 대표로 변경
          await db.update(
            'course_executions',
            {'course_id': primaryId},
            where: 'course_id = ?',
            whereArgs: [dupId],
          );
          // 중복 코스의 steps 삭제
          await db.delete('steps', where: 'course_id = ?', whereArgs: [dupId]);
          // 중복 코스 삭제
          await db.delete('courses', where: 'course_id = ?', whereArgs: [dupId]);
        }
      }
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
      orderBy: 'course_id DESC',
    );
    return maps.map((m) => CourseModel.fromMap(m)).toList();
  }

  Future<CourseModel?> getCourseById(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
    if (maps.isEmpty) return null;
    return CourseModel.fromMap(maps.first);
  }

  /// 하위 호환 — 기존 호출처를 위해 유지.
  Future<CourseModel?> getSavedCourseById(int courseId) => getCourseById(courseId);

  Future<int> updateCourse(CourseModel course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap()..remove('course_id'),
      where: 'course_id = ?',
      whereArgs: [course.courseId],
    );
  }

  Future<int> deleteCourse(int courseId) async {
    final db = await database;
    await db.delete('course_executions', where: 'course_id = ?', whereArgs: [courseId]);
    await db.delete('steps', where: 'course_id = ?', whereArgs: [courseId]);
    return await db.delete('courses', where: 'course_id = ?', whereArgs: [courseId]);
  }

  /// 한번이라도 실행 완료된 코스 목록 (실행 기록이 존재하는 코스).
  Future<List<CourseModel>> getCompletedCourses() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT c.* FROM courses c
      INNER JOIN course_executions e ON c.course_id = e.course_id
      ORDER BY c.course_id DESC
    ''');
    return maps.map((m) => CourseModel.fromMap(m)).toList();
  }

  // ==================== COURSE EXECUTIONS ====================

  Future<int> insertExecution(ExecutionModel execution) async {
    final db = await database;
    final map = {
      'course_id': execution.courseId,
      'executed_at': execution.executedAt.toIso8601String(),
      'before_data': jsonEncode(execution.before),
      'after_data': jsonEncode(execution.after),
    };
    final id = await db.insert('course_executions', map);

    // 코스 상태를 completed로 업데이트
    await db.update(
      'courses',
      {'status': 'completed'},
      where: 'course_id = ?',
      whereArgs: [execution.courseId],
    );

    return id;
  }

  /// 특정 코스의 실행 기록 (최신순).
  Future<List<ExecutionModel>> getExecutionsByCourse(int courseId) async {
    final db = await database;
    final maps = await db.query(
      'course_executions',
      where: 'course_id = ?',
      whereArgs: [courseId],
      orderBy: 'executed_at DESC',
    );
    return maps.map((m) => _executionFromDbMap(m)).toList();
  }

  /// 최근 실행 기록 (코스 정보 포함, 최신순).
  /// 반환: List of (CourseModel, ExecutionModel) 쌍.
  Future<List<(CourseModel, ExecutionModel)>> getRecentExecutions({int limit = 3}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.*, e.execution_id, e.executed_at AS exec_at,
             e.before_data, e.after_data
      FROM course_executions e
      INNER JOIN courses c ON c.course_id = e.course_id
      ORDER BY e.executed_at DESC
      LIMIT ?
    ''', [limit]);

    return maps.map((m) {
      final course = CourseModel.fromMap(m);
      final execution = ExecutionModel(
        executionId: m['execution_id'] as int?,
        courseId: m['course_id'] as int,
        executedAt: DateTime.parse(m['exec_at'] as String),
        before: m['before_data'] != null && (m['before_data'] as String).isNotEmpty
            ? Map<String, int>.from(jsonDecode(m['before_data'] as String) as Map)
            : const {},
        after: m['after_data'] != null && (m['after_data'] as String).isNotEmpty
            ? Map<String, int>.from(jsonDecode(m['after_data'] as String) as Map)
            : const {},
      );
      return (course, execution);
    }).toList();
  }

  /// 전체 실행 기록 (코스 정보 포함, 최신순) — 최근 운동 전체 페이지용.
  Future<List<(CourseModel, ExecutionModel)>> getAllExecutions() async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT c.*, e.execution_id, e.executed_at AS exec_at,
             e.before_data, e.after_data
      FROM course_executions e
      INNER JOIN courses c ON c.course_id = e.course_id
      ORDER BY e.executed_at DESC
    ''');

    return maps.map((m) {
      final course = CourseModel.fromMap(m);
      final execution = ExecutionModel(
        executionId: m['execution_id'] as int?,
        courseId: m['course_id'] as int,
        executedAt: DateTime.parse(m['exec_at'] as String),
        before: m['before_data'] != null && (m['before_data'] as String).isNotEmpty
            ? Map<String, int>.from(jsonDecode(m['before_data'] as String) as Map)
            : const {},
        after: m['after_data'] != null && (m['after_data'] as String).isNotEmpty
            ? Map<String, int>.from(jsonDecode(m['after_data'] as String) as Map)
            : const {},
      );
      return (course, execution);
    }).toList();
  }

  /// 운동한 날짜 Set (캘린더/스트릭 표시용).
  Future<Set<DateTime>> getExerciseDates() async {
    final db = await database;
    final maps = await db.query(
      'course_executions',
      columns: ['executed_at'],
    );
    final dates = <DateTime>{};
    for (final m in maps) {
      final dt = DateTime.parse(m['executed_at'] as String);
      dates.add(DateTime(dt.year, dt.month, dt.day));
    }
    return dates;
  }

  ExecutionModel _executionFromDbMap(Map<String, dynamic> map) {
    return ExecutionModel(
      executionId: map['execution_id'] as int?,
      courseId: map['course_id'] as int,
      executedAt: DateTime.parse(map['executed_at'] as String),
      before: map['before_data'] != null && (map['before_data'] as String).isNotEmpty
          ? Map<String, int>.from(jsonDecode(map['before_data'] as String) as Map)
          : const {},
      after: map['after_data'] != null && (map['after_data'] as String).isNotEmpty
          ? Map<String, int>.from(jsonDecode(map['after_data'] as String) as Map)
          : const {},
    );
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

  Future<List<PostureResultModel>> getAllPostureResults() async {
    final db = await database;
    final maps = await db.query(
      'posture_results',
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

  /// 총 실행 횟수 — executions 테이블의 row 수.
  Future<int> getTotalExecutions() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM course_executions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// 평균 피로도 감소.
  /// course_executions의 before_data/after_data에서 부위별 피로도 차이의 평균을 계산.
  Future<double> getAverageFatigueReduction() async {
    final db = await database;
    final maps = await db.query(
      'course_executions',
      columns: ['before_data', 'after_data'],
      where: "before_data IS NOT NULL AND after_data IS NOT NULL AND before_data != '{}' AND after_data != '{}'",
    );
    if (maps.isEmpty) return 0.0;

    int totalReduction = 0;
    int count = 0;
    for (final map in maps) {
      final beforeStr = map['before_data'] as String?;
      final afterStr = map['after_data'] as String?;
      if (beforeStr == null || afterStr == null) continue;
      if (beforeStr == '{}' || afterStr == '{}') continue;
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
