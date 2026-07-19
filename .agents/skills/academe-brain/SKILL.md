---
name: academe-brain
description: MASTER Brain context and memory manager for the ACADEMe workspace. Consolidates architecture, graph knowledge, and conventions for the Flutter/FastAPI learning platform. Integrates with Graphify.
---

# ACADEMe Brain: The Master Context

Check this skill FIRST when starting any task, planning features, or making architectural decisions in this workspace.

---

## 1. Graphify Memory System

A knowledge graph lives at `graphify-out/` with 2615 nodes, 3918 edges, 235 communities.

**First Action:** Read `graphify-out/GRAPH_REPORT.md` and open `graphify-out/graph.html`.

**Update:** After introducing new modules, run `graphify update .` to regenerate.

### God Nodes (Most Connected)
`package:flutter/material.dart` (110), `l10n.dart` (47), `TeacherService` (45), `LiveClassResponse` (39), `LiveClassCreate` (37), `TeacherProfileResponse` (37), `StudentInfo` (37), `CourseService` (37), `TeacherProfileUpdate` (36), `TeacherPreferencesUpdate` (36)

### Top Communities
0: Flutter Material UI (274), 1: Community Chat (253), 2: AskMe Screen (157), 3: Home Screen (155), 4: Backend BaseModel (115), 5: Flash Card Widgets (103), 6: Token/Auth Response (79), 7: Profile Page (79), 8: Main Entry (74), 9: QuizService/Progress (66), 10: Teacher Profile (66), 11: CourseService (56), 12: Manage Teachers (60), 13: Topic View (56), 14: API Endpoints (50), 15: Backend main.py (49), 16: Course Widgets (48), 17: FirebaseService (28), 18: TeacherExamService (32), 19: Teacher Student Mgmt (32), 20: Lessons Screen (31), 21: Auth Service (31), 22: Backend Docs (29), 23: Teacher Live Classes (26), 24: AdminTeacherService (19), 25: FirestoreDataExtractor (12), 26-30: Bottom Nav, Auth Access, Course Service aggregations

### Extraction
26% INFERRED (1032 edges, avg 0.54 confidence), 0% AMBIGUOUS. 2806 AST + 366 semantic nodes merged.

---

## 2. Project Identity

**ACADEMe** is an AI-powered multilingual educational platform. Students learn through structured courses with topics, subtopics, materials, and quizzes. An AI tutor ("ASKMe") provides 24/7 assistance via text, image, audio, video, and document processing. Teachers manage classes, create exams, schedule live classes, and track progress. Admins oversee teachers and content.

Supported languages: English, French, Spanish, German, Chinese, Arabic, Hindi.

---

## 3. Technology Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — Provider pattern, MVC controllers |
| Backend | Python FastAPI 0.115.8, Uvicorn 0.34.0 |
| Database | Firebase Firestore (NoSQL) + Firebase Realtime DB (chat) |
| AI | Gemini 2.0 Flash (multimodal) |
| STT | Whisper (Hugging Face Inference API) |
| Translation | LibreTranslate (self-hosted) |
| Auth | JWT HS256 (access 1hr + refresh 30d) + Firebase Auth |
| Media | Cloudinary |
| Email | SMTP (Gmail) |
| Deployment | Railway (Docker, python:3.10-slim) |

---

## 4. Architecture — 8 Subsystems

### 4.1 Flutter Frontend

**Init & Providers** (`main.dart`): MaterialApp.router → `AppStateManager` (ChangeNotifier) controls auth flow. Providers: `AppStateManager`, `LanguageProvider`, `BottomNavProvider`, `ProgressProvider`.

**Auth Flow:** `AuthWrapper` (stateless widget) checks `AppStateManager.isAuthenticated`. If logged in → role-based routing (`StudentShell`/`TeacherShell`). Login via email/password or Google OAuth. Firebase custom token for Realtime DB chat.

**Screens (Student):**
- `HomeScreen` — course cards, continue learning, banners, search
- `CourseListScreen` — tabs for courses, communities, progress, profile
- `CourseWidgets` — `ASKMeButton`, `CourseCard`, `ComingSoonPopup`
- `ProgressScreen` — summary, course progress, activity chart, study time, motivation popup
- `AskMeScreen` — multimodal chat with attachments (image, video, audio, document). `ChatBubble`, `ChatHistoryDrawer`
- `ProfilePage` — user info, class, language, privacy, logout
- `CommunityChatScreen` — Firebase Realtime DB chat, topic-based rooms
- `TopicViewScreen` — tabbed view: flashcards, lessons, overview, test report
- `FlashCardScreen` — swipeable flashcards (text + markdown rendering)
- `LessonsScreen` — materials (text/video), quizzes per subtopic
- `OverviewScreen` — subtopic content listing
- `TestReportScreen` — score cards, performance graph, detailed analysis, PDF export
- `Onboarding` — splash, animated intro, login/signup with OTP, forgot password, class selection

**Screens (Teacher):**
- `TeacherHomeScreen` — dashboard
- `TeacherContentScreen` — manage courses, topics, materials
- `TeacherLiveClassesScreen` — schedule, upcoming, recorded classes
- `TeacherProfileScreen` — profile editing
- `TeacherStudentManagementScreen` — class analytics, student progress

**Screens (Admin):**
- Admin dashboard with `ManageTeachersTab`, `TeacherDetailsScreen`, course listing

**Controllers (13 total):**
- `HomeController` (singleton) — courses, user data, caching
- `CourseController` — course listing, category filter
- `ProgressController` — progress data, visual analytics
- `AskMeController` — chat messages, file uploads, AI processing, session management
- `ProfileController` — user profile, logout
- `CommunityController` — community data
- `TopicApiController` — topics, subtopics, materials, quizzes API calls
- `TopicCacheController` — local caching with TTL
- `AppLifecycleController` — app lifecycle events
- `FlashCardController` — flashcard navigation, state
- `LessonsController` — lesson material, resume point
- `OverviewController` — subtopic list
- `TestReportController` — test scores, analytics, PDF

**Theming:** `academe_theme.dart` — dark theme, custom component themes (AppBar, BottomSheet, Chip, Checkbox, TextField, ElevatedButton, OutlinedButton), `AColors`, `ATexts`, `AImages`.

**Localization:** `l10n.dart` with 6 locale files (en, fr, es, zh, hi, ar).

### 4.2 FastAPI Backend

**Entry** (`main.py`): FastAPI(title="ACADEMe API") → mounts 12 routers under `/api` + 7 direct AI processing endpoints.

**Routes (12 files):**
- `users.py` — auth (signup, login, OTP, refresh, logout, Google, class update)
- `firebase_auth.py` — Firebase custom token generation
- `teacher_auth_routes.py` — teacher email verification
- `courses.py` — course CRUD (admin)
- `topics.py` — topics, subtopics, materials CRUD (admin)
- `quizzes.py` — quizzes, questions CRUD (admin)
- `student_progress.py` — progress logging, listing, updating
- `progress_visuals.py` — visual analytics data
- `ai_recommendations.py` — personalized learning recommendations
- `ai_analytics.py` — AI performance analysis
- `discussions.py` — discussion forum (unauthenticated)
- `teacher_routes.py` — teacher profile, courses, live classes, analytics
- `teacher_exam_routes.py` — exam CRUD, publishing, submissions, analytics
- `admin_teacher_routes.py` — teacher management, analytics

### 4.3 Authentication System

**Dual Strategy:** Firebase Auth tokens (via `auth.verify_id_token()`) + custom JWT HS256 tokens.

**JWT Tokens:** Access token (1hr, `JWT_SECRET_KEY`) + Refresh token (30d, `REFRESH_SECRET_KEY`). Refresh tokens stored in `refresh_tokens` Firestore collection. Revoked in `token_blacklist`.

**Password:** bcrypt via passlib. OTP (6-digit, 10-min expiry, in-memory dicts, SMTP delivery).

**Roles:** `student` (default), `teacher` (via `teacher_profiles`), `admin` (via `admins` collection). Determined dynamically by `determine_user_role()`.

### 4.4 Course Content Hierarchy

```
Course → Topic → Subtopic → Material (text/image/video/audio/document)
                          → Quiz → Questions (multiple choice)
```

Every content entity stores `languages: { en: {title,desc}, fr:{...}, es: {...}, de:{...}, zh:{...}, ar:{...}, hi:{...} }`. Served via `target_language` query param, fallback to English.

Two parallel collections: `/courses` (admin-managed) and `/teacher_courses` (teacher-owned, tracked via `teacher_id`).

### 4.5 AI Pipeline

**Gemini 2.0 Flash** (system prompt: "Your name is ASKMe, the 24/7 AI Tutor of ACADEMe"):

| Agent | Input | Pipeline |
|-------|-------|----------|
| `TextAgent` | Text | Detect language → Translate to EN → Gemini → Return |
| `DocumentAgent` | PDF/DOCX/TXT | Extract text → Detect lang → Translate to EN → Gemini |
| `ImageAgent` | JPEG/PNG/GIF | Validate → Detect lang → Translate prompt → Gemini with image → Translate response |
| `AudioAgent` | MP3/WAV/FLAC/OGG/WEBM | Whisper transcribe → Detect lang → Translate to EN → Gemini |
| `VideoAgent` | MP4/MKV/WEBM/AVI | Save 1MB chunks → Gemini with video → Cleanup |
| `STTAgent` | Audio | Whisper transcription only → Return {text, language} |
| `ResponseTranslationAgent` | Text | Detect source → Translate to EN → Translate to target |

**AI Recommendation Pipeline:** Fetch progress → Extract IDs → Fetch ID-to-name mappings from Firestore → Enrich data → Gemini prompt → Translate to target language.

**AI Processing Endpoints:** `POST /api/process_{text,stt,translate_response,document,image,audio,video}`.

### 4.6 Progress Tracking

Progress logged per activity: `{course_id, topic_id, subtopic_id, material_id, quiz_id, question_id, score, status, activity_type, metadata, timestamp}`.

**Activity types:** `view`, `quiz_attempt`, `discussion`, `reading`. **Status:** `incomplete`, `complete`.

Progress stored in `/users/{uid}/progress/{progressId}`. Updated when user changes class (all progress deleted).

**Visual Analytics** (`ProgressVisualResponse`): quizzes count, materials read, avg/max score, score timeline, time spent per day, topic-level aggregation.

**AccurateProgressService:** Calculates completion rate (materials completed / total materials) and accurate quiz scores.

### 4.7 Teacher & Exam System

**Teacher Features:** Profile management, course creation (parallel `/teacher_courses`), live class scheduling (Zoom, 45 min default), class recordings, student progress viewing, class analytics.

**Exam System** (`teacher_exams` collection):
- Exams have quiz questions (MCQ) and subjective questions
- Workflow: Create → Add questions → Publish (min 1 question required)
- Unpublish blocked if submissions exist
- Submissions tracked in `exam_submissions`
- Analytics: participation rate, performance, score distribution

### 4.8 Admin Panel

**AdminTeacherService:** Add teacher (profile + role update), remove (revert to student), update, list all (with stats: subject summary, class distribution, performance), detailed stats per teacher, analytics overview.

---

## 5. Firestore Collections

| Collection | Purpose | Key Fields |
|-----------|---------|------------|
| `/users/{uid}` | User profiles | name, email, password(bcrypt), student_class, role, photo_url |
| `/users/{uid}/progress/{pid}` | Progress entries | course_id, topic_id, score, status, activity_type, timestamp |
| `/courses/{cid}` | Admin courses | class_name, languages:{en:{title,desc},...}, created_at |
| `/courses/{cid}/topics/{tid}` | Topics | languages map, created_at |
| `/courses/{cid}/topics/{tid}/subtopics/{sid}` | Subtopics | languages map, created_at |
| `/courses/{cid}/topics/{tid}/materials/{mid}` | Topic materials | type, category, content, languages |
| `/courses/{cid}/topics/{tid}/quizzes/{qid}` | Topic quizzes | title, description, languages |
| `.../quizzes/{qid}/questions/{quid}` | Quiz questions | question_text, options[4], correct_option, languages |
| `/teacher_courses/{cid}` | Teacher courses | Same as courses + teacher_id |
| `/teacher_profiles/{email}` | Teacher profiles | user_id, name, subject, allotted_classes[], bio, preferences |
| `/teacher_exams/{eid}` | Exams | teacher_id, class_name, is_published, duration_minutes, total_marks |
| `/teacher_exams/{eid}/questions/{qid}` | Exam questions | question_type, question_text, options, correct_answer, marks |
| `/exam_submissions/{sid}` | Submissions | exam_id, student_id, quiz_score, total_score, status |
| `/live_classes/{lid}` | Live classes | teacher_id, title, class_name, platform, scheduled_time, status, recording_url |
| `/discussions/{did}` | Forum threads | topic_id, title, created_by |
| `/discussions/{did}/messages/{mid}` | Messages | user_id, content |
| `/admins/{email}` | Admin list | (existence-based) |
| `/refresh_tokens/{tid}` | Active refresh tokens | user_id, expires_at |
| `/token_blacklist/{tid}` | Revoked tokens | revoked_at |
| `/id-mapping/default/{collection}/{id}` | ID→name maps | name/title/content for AI enrichment |

---

## 6. Frontend Features (Complete)

| Feature | Screens | Controllers | Models |
|---------|---------|-------------|--------|
| Auth & Onboarding | AnimatedSplash, Onboarding, Login, Signup, ForgotPassword, ClassSelect | AppStateManager (provider) | AppUser |
| Home | HomeScreen, CourseCard, Shimmer, Search, Banner, Drawer | HomeController | Course (home_model) |
| Courses | CourseListScreen, CourseTabBar, CourseCard, SearchUI | CourseController | Course (course_model), CourseDataCache |
| AskMe Chat | AskMeScreen, ChatBubble, ChatHistory, AttachmentOptions | AskMeController | ChatMessage |
| Progress | ProgressScreen, SummarySection, CourseProgress, ActivitySection, StudyTime, MotivationPopup | ProgressController | ProgressHelpers (grades) |
| Profile | ProfilePage, LanguageSelection, PrivacyPolicy, ClassPage | ProfileController | UserModel |
| Community | CommunityChatScreen, MyCommunityScreen, CommunityWidgets | CommunityController | CommunityModel |
| Topics | TopicViewScreen, TopicCard | TopicApiController, TopicCacheController, AppLifecycleController | TopicCacheData |
| Flashcards | FlashCardScreen, FlashCardContentWidget | FlashCardController | FlashCardMaterial, FlashCardQuiz |
| Lessons | LessonsScreen, LessonsAndQuizzesWidget, MaterialView | LessonsController | SubtopicContent, SubtopicState, LessonsSectionParams |
| Overview | OverviewScreen, OverviewWidgets, QSection | OverviewController | OverviewModel |
| Test Reports | TestReportScreen, ScoreCard, PerformanceGraph, DetailedAnalysis | TestReportController | TestReportModel, PerformanceMetrics |
| Teacher | TeacherHome, TeacherContent, TeacherLiveClasses, TeacherProfile, TeacherStudentMgmt | (controller per screen) | (teacher models) |
| Admin | ManageTeachersTab, TeacherDetails, CourseManagement | (none) | (admin models) |

---

## 7. Backend Services

| Service | File | Key Methods |
|---------|------|-------------|
| `AuthService` | `services/auth_service.py` | generate_otp, send_otp_email, register_user, login_user, google_signin_or_signup, reset_password |
| `FirebaseService` | `services/firebase_service.py` | get_courses_by_ids, create_custom_token, batch_get_documents, thread pool (10 workers) |
| `GeminiService` | `services/gemini_service.py` | get_gemini_response(prompt, history, image_path, video_path), process_text_with_gemini |
| `WhisperService` | `services/whisper_service.py` | transcribe_audio → {text, language} via Hugging Face Inference API |
| `LibreTranslateService` | `services/libretranslate_service.py` | translate_text(source, target), self-hosted endpoint |
| `CourseService` | `services/course_service.py` | create_course (7 languages), get_courses (filter by class + language) |
| `TopicService` | `services/topic_service.py` | create_topic, get_all_topics, create_subtopic, get_subtopics_by_topic |
| `MaterialService` | `services/material_service.py` | add_material (translate content), get_materials |
| `QuizService` | `services/quiz_service.py` | add_quiz, get_quizzes, add_question, get_questions, get_all_quizzes |
| `ProgressService` | `services/progress_service.py` | log_progress, get_student_progress, update_progress, get_progress_visuals, delete_user_progress |
| `AIService` | `services/ai_service.py` | get_recommendations (fetch→enrich→Gemini→translate) |
| `DiscussionService` | `services/discussion_service.py` | create_discussion, get_discussions_by_topic, create_message, get_messages |
| `TeacherService` | `services/teacher_service.py` | profile CRUD, class analytics, student progress, live class management, recordings |
| `TeacherCourseService` | `services/teacher_course_service.py` | create/read teacher courses, topics, materials |
| `TeacherExamService` | `services/teacher_exam_service.py` | create, publish, submit, analyze exams with quiz + subjective questions |
| `AdminTeacherService` | `services/admin_teacher_service.py` | add/remove/update teachers, comprehensive stats, analytics overview |
| `AccurateProgressService` | `services/accurate_progress_service.py` | accurate completion rates, quiz scores, class analytics |
| `CloudinaryService` | `utils/cloudinary_service.py` | upload_file(file, folder) → secure_url |

---

## 8. Pydantic Models (Backend)

**User:** `UserCreate`, `UserLogin`, `TokenResponse`, `RefreshTokenRequest`, `UserUpdateClass`
**Course:** `CourseCreate`, `CourseResponse`
**Topic:** `TopicBase`, `TopicCreate`, `TopicResponse`, `SubtopicBase`, `SubtopicResponse`
**Material:** `MaterialCreate` (type, category, content), `MaterialResponse`
**Quiz:** `QuizCreate`, `QuizResponse`, `QuestionCreate`, `QuestionResponse`
**Progress:** `ProgressBase`, `ProgressCreate`, `ProgressUpdate`, `ProgressVisualResponse`
**Graph/Visuals:** `HeroGraphData`, `ScoreTimelineEntry`, `TopicProgress`, `ProgressVisualResponse`
**Discussion:** `DiscussionBase/Create/Response`, `MessageBase/Create/Response`
**AI:** `AIAnalysisRequest/Response`, `AIRecommendationResponse`
**Teacher:** `TeacherProfileUpdate/Response`, `TeacherPreferencesUpdate`, `CourseCreate/Response`, `TopicCreate/Response`, `MaterialCreate/Response`, `LiveClassCreate/Response`, `ClassAnalytics`, `StudentInfo`, `StudentProgressSummary`, `ClassProgressOverview`, `StudentDetailedAnalytics`, `ClassProgressSummary`
**Message:** `Message` (text + language)

---

## 9. API Endpoints Summary

**Auth** (11 endpoints): send-otp, forgot-password, reset-password, signup, login, me, refresh, logout, update_class, admins, google-signin
**Firebase** (1): firebase-token
**Teacher Auth** (1): teacher-emails
**Courses** (2): create, list(filtered by class)
**Topics** (8): add/list topics, subtopics, materials (topic-level + subtopic-level)
**Quizzes** (8): create/list quizzes and questions (topic + subtopic)
**Progress** (3): log, list, update
**Visuals** (1): progress-visuals
**AI** (2): recommendations, analyze
**Discussions** (4): create, list by topic, post message, list messages
**Teacher** (19): profile CRUD, preferences, allotted-classes, students, analytics, courses CRUD, topics CRUD, materials CRUD, live classes CRUD, recordings, progress, progress-summary
**Teacher Exams** (12): create, my-exams, details, update, add-quiz-question, add-subjective-question, remove-question, publish, unpublish, submissions, analytics, delete
**Admin Teachers** (6): add, remove, update, list-all, detailed-stats, analytics-overview

---

## 10. Data Flow Patterns

**Auth Flow:** Email/password → POST /login → Backend verifies bcrypt hash → Generates JWT (access 1hr + refresh 30d) → Stores refresh in Firestore → Returns TokenResponse with user data → Frontend stores in FlutterSecureStorage + SharedPrefs.

**Content Retrieval:** GET /courses?target_language=fr → Backend reads Firestore → Extracts French from languages map (falls back to English) → Returns translated CourseResponse list.

**Progress Logging:** User views material/completes quiz → POST /progress → Backend stores entry in users/{uid}/progress/{pid} with activity_type, score, status.

**AI Chat:** User sends text/image/audio/video → POST /api/process_{type} → Backend routes to appropriate agent → Agent pipeline (detect lang → translate → Gemini → translate back) → Returns {response, language}.

**Recommendations:** GET /recommendations → Fetch progress → Extract IDs → Fetch id-mapping → Enrich → Gemini prompt → Translate → Return.

**Live Class:** Teacher schedules → POST /teacher/classes/schedule → Creates in live_classes with status="scheduled" → POST .../start → status="live" → POST .../share → status="completed" with recording_url.

---

## 11. Key Development Patterns

- **No frontend enums** for roles, activity types, material types — raw strings throughout
- **Cache:** CourseDataCache (30-min TTL), TopicCacheData (timestamp-based)
- **Dual caching:** Local (topic_cache_controller.dart) + Firestore
- **Shimmer widgets** for all loading states
- **Multilingual:** Every content entity stores 7-language map, LibreTranslate for AI responses
- **ID Mapping:** Firestore subcollections `id-mapping/default/{collection}` for AI enrichment
- **Thread pool:** FirebaseService uses 10-worker ThreadPoolExecutor for async Firestore ops
- **File upload:** Cloudinary with auto-detection, separate folders for admin/teacher materials
- **Roles:** student (default), teacher (profile check), admin (collection check)

---

## 12. Deployment

**Docker:** `python:3.10-slim`, port 8000, `uvicorn main:app --host 0.0.0.0`
**Railway:** Production Firebase creds via `FIREBASE_CREDENTIALS_BASE64` env var
**Nix:** direnv + flake.nix for reproducible dev environment

---

## 13. Operational Protocol

- **No noise:** No redundant comments, minimal formatting changes.
- **Explain & Confirm:** Explain changes, then ask "Should I start?".
- **Zero regression:** Never break auth flows, API contracts, caching, or multilingual content.
- **Test:** No test framework currently — verify manually.

---

## 14. Knowledge Gaps (From Graph)

- 26% INFERRED edges — many AI-reasoned connections need human verification
- 235 communities with many single-node isolates — documentation gaps
- No AMBIGUOUS edges detected — model may be overconfident
- No test suite exists
- In-memory OTP storage (lost on restart, should use Redis)

---

## When in Doubt

If you are ever unsure, read this `SKILL.md` and check the `graphify-out/` memory. If you are ever unsure, read this `SKILL.md` and check the `graphify-out/` memory.
