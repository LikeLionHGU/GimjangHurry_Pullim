/// AI 기반 근막이완 코스 생성 엔진 라이브러리.
///
/// ```dart
/// import 'package:likelion_mid_hackathon/course_generator/course_generator_library.dart';
///
/// final generator = CourseGenerator();
/// final course = await generator.generateCourse(
///   CourseRequest(
///     fatigueEntries: [
///       FatigueEntry(face: BodyFace.back, part: BodyPart.neck, level: 4),
///     ],
///     ownedTools: [11, 7, 2],
///     availableTime: 1200,
///   ),
/// );
/// ```
library;

export '../assets/body_assets.dart' show BodyFace, BodyPart;
export 'course_generator.dart';
export 'models/models.dart';
export 'move_filter.dart';
export 'openai_client.dart' show OpenAiClient, OpenAiException;
export 'prompt_builder.dart';
export 'response_parser.dart' show ResponseParser, CourseValidationException;
