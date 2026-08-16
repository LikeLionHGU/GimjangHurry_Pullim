// ignore_for_file: avoid_print
//
// 코스 생성 엔진 CLI 테스트 스크립트.
// Flutter 앱 빌드 없이 터미널에서 엔진을 단독 실행하여 결과를 확인할 수 있다.
//
// 근막이완 코스 생성 예제.
//
// 실행 방법:
//   1. 프로젝트 루트에 .env 파일 생성:
//      OPENAI_API_KEY=sk-...
//
//   2. 실행:
//      dart run example/generate_course_example.dart
//
// 또는 환경변수로 직접 전달:
//   OPENAI_API_KEY=sk-... dart run example/generate_course_example.dart
import 'dart:io';

import 'package:likelion_mid_hackathon/assets/body_assets.dart';
import 'package:likelion_mid_hackathon/assets/move_assets.dart';
import 'package:likelion_mid_hackathon/assets/tool_assets.dart';
import 'package:likelion_mid_hackathon/course_generator/course_generator_library.dart';
import 'package:likelion_mid_hackathon/course_generator/env_loader.dart';

Future<void> main() async {
  // .env 로드 및 API 키 확인
  await EnvLoader.load();
  final apiKey = EnvLoader.get('OPENAI_API_KEY');
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ OPENAI_API_KEY가 설정되지 않았습니다.');
    print('   프로젝트 루트에 .env 파일을 만들고 OPENAI_API_KEY=sk-... 를 추가하거나,');
    print('   export OPENAI_API_KEY="sk-..." 로 환경변수를 설정해주세요.');
    exit(1);
  }

  // 입력 조건 설정 — BodyFace + BodyPart + 피로도로 지정
  final request = CourseRequest(
    fatigueEntries: [
      FatigueEntry(face: BodyFace.back, part: BodyPart.neck, level: 4),      // 뒤-목
      FatigueEntry(face: BodyFace.back, part: BodyPart.shoulder, level: 3),  // 뒤-어깨
      FatigueEntry(face: BodyFace.back, part: BodyPart.waist, level: 5),     // 뒤-허리
    ],
    ownedTools: [11, 7, 2], // 피넛볼, 라크로스볼, 그리드 폼롤러
    availableTime: 1200, // 20분
  );

  print('═══════════════════════════════════════════════════════════');
  print('  AI 근막이완 코스 생성기');
  print('═══════════════════════════════════════════════════════════');
  print('');

  // 입력 조건 출력
  print('📋 입력 조건');
  print('─────────────────────────────────────────────────────────');
  print('  피로 부위:');
  for (final entry in request.fatigueEntries) {
    final bodyNames = entry.bodyIndexes
        .map((i) => kBodies[i]?.name ?? '?')
        .join(', ');
    print('    • ${entry.displayLabel} (피로도 ${entry.level}/5) → $bodyNames');
  }
  print('  보유 도구:');
  for (final toolIndex in request.ownedTools) {
    final tool = kTools[toolIndex];
    print('    • ${tool?.displayName ?? "?"} (인덱스 $toolIndex)');
  }
  print('  가용 시간: ${request.availableTime ~/ 60}분 ${request.availableTime % 60}초');
  print('');

  // 후보 동작 미리보기
  final generator = CourseGenerator();
  final candidates = generator.previewCandidates(request);
  print('🔍 후보 동작: ${candidates.length}개');
  for (final move in candidates) {
    print('    [${move.index}] ${move.name} (${move.posture.label})');
  }
  print('');

  // 코스 생성
  print('⏳ AI가 코스를 생성 중입니다...');
  print('');

  try {
    final course = await generator.generateCourse(request);

    // 결과 출력
    print('✅ 코스 생성 완료!');
    print('═══════════════════════════════════════════════════════════');
    print('');
    print('📝 요약: ${course.summary}');
    print('');
    print('⏱️  총 소요 시간: ${course.totalDuration ~/ 60}분 ${course.totalDuration % 60}초');
    print('');
    print('─────────────────────────────────────────────────────────');
    print('  코스 상세');
    print('─────────────────────────────────────────────────────────');

    for (var i = 0; i < course.steps.length; i++) {
      final step = course.steps[i];
      final move = kMoves[step.moveIndex];
      final tool = kTools[step.toolIndex];
      final bodyNames =
          move?.body.map((b) => kBodies[b]?.name ?? '$b').join(', ') ?? '?';

      print('');
      print('  ${i + 1}. ${move?.name ?? "동작 ${step.moveIndex}"}');
      print('     도구: ${tool?.displayName ?? "도구 ${step.toolIndex}"}');
      print('     부위: $bodyNames');
      print('     자세: ${move?.posture.label ?? "?"}');
      print('     시간: ${step.duration}초');
      print('     이유: ${step.reason}');
    }

    print('');
    print('═══════════════════════════════════════════════════════════');
  } on NoCandidatesException catch (e) {
    print('❌ 후보 없음: ${e.message}');
  } on OpenAiException catch (e) {
    print('❌ API 오류: ${e.message}');
  } on CourseValidationException catch (e) {
    print('❌ 검증 실패: $e');
  } catch (e) {
    print('❌ 예상치 못한 오류: $e');
  } finally {
    generator.dispose();
  }
}
