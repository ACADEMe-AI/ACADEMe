# ACADEMe — Principal Engineer Review & Roast

**Date:** 2026-07-19  
**Repo:** `albany` (ACADEMe monorepo)  
**Scope:** End-to-end product understanding, architecture judgment, security review, and full technical roast  
**Perspective:** Principal software engineer  

---

# Part 1 — What ACADEMe Actually Is (End-to-End)

## Product thesis

**ACADEMe is a multilingual, AI-tutored learning platform** aimed at class-based school/institution use. Students work through hierarchical content, get help from **ASKMe** (multimodal AI tutor), track progress, and chat. Teachers own content, live classes, and exams. Admins manage teachers and catalog content.

It’s not a MOOC. It’s closer to: **LMS + AI tutor + teacher ops**, with language packing as a first-class feature.

## Roles

| Role | Can do |
|------|--------|
| **Student** | Enroll by class, take courses, flashcards/lessons/quizzes, ASKMe, progress dashboards, community chat |
| **Teacher** | Profile, teacher courses, live classes (Zoom-ish flow), exams (MCQ + subjective), class analytics |
| **Admin** | Teacher lifecycle, course/topic/material/quiz CRUD |

## Content model

```
Course
 └─ Topic
     ├─ Materials (text / image / video / audio / document)
     ├─ Quizzes → Questions
     └─ Subtopics
         ├─ Materials
         └─ Quizzes → Questions
```

Every content blob stores a **7-language map** (`en` / `fr` / `es` / `de` / `zh` / `ar` / `hi`). Clients request `target_language=…`; backend picks the language branch or falls back to English.

Two parallel trees exist: **admin `/courses`** and **teacher `/teacher_courses`**.

## End-to-end flows

### 1. Auth

Email/password or Google → backend verifies → issues **JWT access (1h) + refresh (30d)** → Flutter stores tokens (secure storage + prefs) → `AuthWrapper` validates → routes student / teacher / admin shell.

Dual identity stack: **Firebase Auth** (users, custom tokens for Realtime DB chat) **and** custom JWT for API.

### 2. Learn

Home/courses fetch by **student class + language** → topic view → flashcards / lessons / overview / quizzes → progress events written under `users/{uid}/progress` → progress visuals / recommendations.

### 3. ASKMe

User sends text / image / audio / video / document → `POST /api/process_*` → agent (detect lang → translate → **Gemini 2.0 Flash** → translate back) → chat UI.

### 4. Teacher

Schedule live class → start → share recording. Create exam → add questions → publish → submissions → analytics.

### 5. Admin

Add/remove/update teachers; manage course hierarchy and quizzes.

### 6. Community

Firebase Realtime DB chat rooms (after custom token), separate from Firestore content.

## Architecture in one picture

```
Flutter (Provider + feature folders)
        │  HTTPS /api/*
        ▼
FastAPI (routes → services → Firestore / Gemini / Whisper / LibreTranslate / Cloudinary)
        │
        ├─ Firestore: users, courses, progress, teachers, exams, tokens…
        ├─ Realtime DB: chat
        └─ External: Gemini, Whisper (HF), LibreTranslate, SMTP, Cloudinary
```

**Deploy:** Docker + Railway; Firebase creds via base64 env in prod.

## Repo layout

```
albany/
├── ACADEMe-frontend/   # Flutter app (~135 Dart files under lib/)
├── ACADEMe-backend/    # FastAPI (~66 Python files)
├── graphify-out/       # Knowledge graph (2615 nodes, 3918 edges)
├── .agents/skills/     # Agent skills + academe-brain
├── docs/               # Reviews and documentation
├── README.md
└── railway.json
```

## Technology stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart SDK ^3.6.1), Provider, SecureStorage / SharedPrefs |
| Backend | FastAPI 0.115.8, Uvicorn |
| Data | Firestore + Realtime DB (chat) |
| AI | Gemini 2.0 Flash, Whisper (Hugging Face), LibreTranslate |
| Auth | JWT HS256 (access 1h + refresh 30d) + Firebase Auth |
| Media | Cloudinary |
| Email | SMTP (Gmail) |
| Deploy | Docker + Railway |

## Backend structure

**Entry:** `ACADEMe-backend/main.py`

1. Bootstraps Firebase creds (base64 env on Railway, else `.env`)
2. Mounts routers under `/api`
3. Exposes multimodal AI endpoints directly (`/api/process_text`, `_document`, `_image`, `_audio`, `_video`, `_stt`, `translate_response`)

```
agents/     # 7 multimodal pipelines (text, doc, image, audio, video, STT, translation)
routes/     # 14+ route modules (users, courses, topics, quizzes, progress, teacher, admin…)
services/   # 17 domain services (auth, courses, teacher, exams, Gemini, Whisper…)
models/     # 12 Pydantic model modules
utils/      # auth helpers, Cloudinary, language detection, Firestore helpers
config/     # settings, Cloudinary config
```

## Frontend structure

**Entry:** `ACADEMe-frontend/lib/main.dart`

1. Load `.env` (`BACKEND_URL`, etc.)
2. Init Firebase
3. Load role from prefs
4. Start study-time tracker
5. Run `MultiProvider` → `MaterialApp` with localization

**Providers at root:** `LanguageProvider`, `BottomNavProvider`, `CourseController`, `HomeController`, `ProgressProvider`.

**API surface:** all URLs centralized in `lib/api_endpoints.dart`.

| Area | Path | Notes |
|------|------|--------|
| Onboarding / auth | `started/`, `app/auth/` | Splash, login, signup, OTP, class select, `AuthWrapper` |
| Home | `pages/homepage/` | Course cards, continue learning, banners |
| Courses | `pages/courses/` | List + tabs |
| ASKMe | `pages/ask_me/` | Multimodal chat + history |
| Progress | `pages/progress/` | Charts, study time, summaries |
| Profile | `pages/profile/` | Language, privacy, class |
| Community | `pages/community/` | Realtime chat rooms |
| Topics | `pages/topics/` + `topic_details/` | Flashcards, lessons, overview, test reports |
| Teacher | `app/teacher_panel/` | Home, content, live classes, profile, students |
| Admin | `app/admin_panel/` | Teachers, course/topic/material/quiz CRUD |

## Firestore collections (summary)

| Collection | Purpose |
|-----------|---------|
| `/users/{uid}` | User profiles |
| `/users/{uid}/progress/{pid}` | Progress entries |
| `/courses/{cid}` (+ topics, subtopics, materials, quizzes) | Admin courses hierarchy |
| `/teacher_courses/{cid}` | Teacher-owned courses |
| `/teacher_profiles/{email}` | Teacher profiles |
| `/teacher_exams/{eid}` | Exams + questions |
| `/exam_submissions/{sid}` | Exam submissions |
| `/live_classes/{lid}` | Live class scheduling / recordings |
| `/discussions/{did}` | Forum threads (module present; not mounted in `main.py`) |
| `/admins/{email}` | Admin list |
| `/refresh_tokens/{tid}` | Active refresh tokens |
| `/token_blacklist/{tid}` | Revoked tokens |
| `/id-mapping/default/{collection}/{id}` | ID → name maps for AI enrichment |

---

# Part 2 — Principal Engineer Judgment

## Overall grade

| Axis | Grade | One-liner |
|------|-------|-----------|
| Product vision | **B+** | Clear multi-role edtech story; multilingual is a real differentiator |
| Feature breadth | **B** | Student + teacher + admin + AI is a lot for a small team |
| Architecture coherence | **D+** | Two auth systems, dead codepaths, dual configs, god screens |
| Security | **F** | Token expiry off, unauthenticated AI burn, secrets printed, OTP in RAM |
| Code quality | **D** | 700–1000 line widgets, emoji debug logs as a lifestyle |
| Reliability / ops | **D-** | No tests, no CORS config, no rate limits, error strings as API contract |
| Data design | **C** | Firestore hierarchy is fine; password-in-user-doc and dual trees hurt |
| AI quality | **C-** | “Agent” folder is thin wrappers; translate → Gemini → hope |
| Ship readiness (prod) | **Not ready** | Cool demo / early beta. Not something for kids’ data at scale |

## Principal verdict

This is a **feature-complete prototype dressed as a platform**. The team built the *shape* of an LMS. They did not build the *discipline* of one.

For a student/hackathon/startup MVP: impressive volume.  
For anything with real schools, real PII, or real AI cost: this would get rejected at architecture review in the first 15 minutes.

---

# Part 3 — The Roast

## The tech stack (buffet, not a meal)

**Flutter + FastAPI + Firestore + Firebase Auth + custom JWT + Realtime DB + Gemini + Whisper + LibreTranslate + Cloudinary + Gmail SMTP + Railway.**

That’s not a stack. That’s a **dependency LinkedIn profile**. Every layer is a different company’s failure mode.

- **Flutter:** fine for mobile. The repo also ships **web/linux/windows/macos** scaffolding like platform badges. Cross-platform theater.
- **FastAPI:** good choice. Then: sync Firestore in “async” services, hand-rolled thread pools, and HTTP to `127.0.0.1` for translation inside one process.
- **Firestore as primary DB for hierarchical LMS content:** valid, but relational joins are reimplemented with `id-mapping` collections and prayer. NoSQL when the domain is a **tree with foreign keys**.
- **Firebase Auth + custom JWT:** dual auth is what you do when you can’t decide. Students don’t need two identity providers. This is a **choose-your-own-adventure login**.
- **LibreTranslate + Gemini + Whisper:** three external brains, zero evals, zero cost controls. AI bill is a feature flag named “whoever finds the public endpoint first.”
- **Cloudinary:** fine — until the API secret is **printed at startup**.
- **Gmail SMTP for OTP:** classic app-password-in-env. Still better than the in-memory OTP store.

**Stack roast in one line:** Optimized for *demo slide count*, not *operational surface area*.

---

## Security (incident-report items)

These are not nits. These are “incident report” items.

### 1. Access tokens never expire (showstopper)

**File:** `ACADEMe-backend/utils/auth.py`

```python
jwt.decode(..., options={"verify_exp": False})
```

Expiry is written into the token, then **expiry verification is turned off**. The `ExpiredSignatureError` handlers below are dead branches. Access tokens live forever. “1 hour” in comments is fan fiction.

Same pattern on refresh token verification paths.

### 2. AI endpoints are a public credit card

**File:** `ACADEMe-backend/main.py`

`/api/process_text`, `_image`, `_audio`, `_video`, `_document`, `_stt` — **no auth**. Anyone who can hit the deployment can burn Gemini/Whisper quota and upload arbitrary files. Not “MVP open.” **Leaving the GPU on the sidewalk with a tip jar.**

### 3. Discussions: unauthenticated and not even mounted

**File:** `ACADEMe-backend/routes/discussions.py`

- Zero `get_current_user` / `Depends`
- **Not included in `main.py`**

Dead unauthenticated API or future footgun — a guestbook that never got a door.

### 4. Default JWT secrets

**File:** `ACADEMe-backend/utils/auth.py`

```python
JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", "your_secret_key_here")
REFRESH_SECRET_KEY = os.getenv("REFRESH_SECRET_KEY", "your_refresh_secret_key_here")
```

If env is missing in any deploy, tokens are minted with tutorial strings. **HS256 with “password” energy.**

### 5. Secrets go to stdout

**File:** `ACADEMe-backend/config/cloudinary_config.py`

Prints cloud name, API key, **and API secret** at import/startup. Logs become free threat intel.

### 6. OTP in a process-local dict

**File:** `ACADEMe-backend/services/auth_service.py`

```python
# In-memory OTP storage (use Redis in production)
otp_storage = {}
```

The confession is in the comment. Restart = wipe OTPs. Multi-instance = random failures. Brute force = no rate limit in sight.

### 7. Passwords stored in Firestore user docs

Firebase Auth already has passwords. The app **also** stores bcrypt hashes in `/users/{uid}` and verifies against Firestore on login. Dual write, dual failure modes, larger blast radius if Firestore rules are wrong.

### 8. Exception messages as API responses

Pattern across services:

```python
detail=f"Error creating exam: {str(e)}"
```

Clients and attackers get stack-shaped gossip. Observability for adversaries.

### 9. No CORS configuration found, no rate limiting found

Open AI + open OTP + no throttle. All-you-can-eat buffet with no bouncer.

**Security grade: F.** Not “needs hardening.” **Needs an incident tabletop before first real school pilot.**

---

## Backend architecture (enterprise cosplay)

- **Layering exists** (`routes` / `services` / `models` / `agents`) — good instinct.
- **Agents are not agents.** `text_agent.py` is roughly four lines: detect → translate → Gemini. Calling that an “agent” is like calling a toaster a sous-chef.
- **`configs.py` and `config/settings.py` both load Gemini keys.** Two sources of truth is zero sources of truth.
- **Admin router double-mounted** (`admin_teacher_router` and `admin_teacher_routes.router` in `main.py`). Paste-driven development.
- **Course creation translates by HTTP-calling itself** at `http://127.0.0.1:8000/api/translate_response` (`course_service.py`). A network round-trip to the same process because a function import was too mainstream.
- **`except Exception` → 500 with stringified error** is house style. Consistency of the wrong kind.
- **Emoji logging** (`🔍` `🔥` `⚠️`) in production services. Logs look like a group chat debugging a science fair project.
- **Teacher service ~682 lines.** God class. When everything is a method of `TeacherService`, nothing is a boundary.

A **service layer** was built, then every service became a **dumping ground**.

---

## Frontend architecture (MVC with commitment issues)

Feature folders (`screens` / `controllers` / `models` / `widgets`) — **good structure on paper**.

Then reality (approximate line counts at review time):

| File | Lines | Crime |
|------|------:|-------|
| `profile_page.dart` | 1021 | A screen that ate a feature team |
| `teacher_live_classes_screen.dart` | 952 | UI + logic + networking smoothie |
| `flash_card_widget.dart` | 938 | Widget? Or small app? |
| `teacher_student_management_screen.dart` | 924 | Dashboard as one file |
| `signup_view.dart` | 864 | Signup is not a novella |
| `auth_service.dart` | 736 | God service of auth |
| `ask_me_screen.dart` | 712 | Chat UI doing everything |

**Provider + ChangeNotifier + singleton controllers** (`HomeController`, `TopicApiController`, caches as factories). Provider for DI theater, then **singletons so state can leak between sessions**. Logout becomes: “did we clear the singleton?”

**Emoji `debugPrint` everywhere** as logging personality. Noise culture.

**Roles as raw strings** (`'admin'`, `'teacher'`, `'student'`) across FE and BE. One typo and someone is a student forever — or an admin for a day.

**ASKMe controller hardcodes error strings in multiple languages** *inside the controller*, while the app already has `l10n`. Localization infrastructure exists; a **second localization system** was copy-pasted next to it.

**Admin panel under `lib/app/admin_panel/`** is flat files (`topic.dart`, `subtopic.dart`) while student features get the nice folder structure. Admin is the neglected middle child.

---

## Testing (the empty museum)

- Backend: **no tests**.
- Frontend: **default Flutter counter widget test** in `test/widget_test.dart` that still looks for `0` / `1` / `Icons.add` — for an education app that has **no counter**. Fossil from `flutter create`. The test folder was never treated as product code.

~200 Dart/Python source files of product and **zero meaningful automated verification**. Every deploy is a confidence ritual.

No tests + infinite JWT + public AI endpoints = **“move fast and break students’ grades.”**

---

## Product / engineering honesty check

### README claims vs code

README markets personalized paths, adaptive difficulty, gamification, certifications, AI-moderated forums, study groups.

Code delivers: **courses, quizzes, a chat tutor, progress logs, teacher exams, live class scheduling**.

Still a product. Marketing is **Series B vocabulary on pre-seed plumbing**. Adaptive assessments? Where’s the difficulty model? Gamified badges? Progress charts ≠ game loop. AI-moderated forums? Discussions aren’t wired into `main.py`.

### Multilingual: ambitious, uneven

Storing 7 languages per content node is a real design choice. Translating via self-HTTP + LibreTranslate on create is fragile. ASKMe’s “translate everything through English” is a **telephone game** for pedagogy — subtle math/science phrasing dies in transit, with **no quality bar, no human review queue, no glossary**.

### Dual course systems

Admin courses + teacher courses means **two schemas, two codepaths, two UIs** for the same pedagogical idea. Bugs get fixed twice forever.

### Cost model (or lack thereof)

Unauthenticated multimodal Gemini + video uploads. No product pricing story in code — only an open pipe. At scale this isn’t “AI-powered education.” It’s **a non-profit for Google Cloud**.

---

## What’s actually good

Credit so the roast has teeth:

1. **Multi-role surface area shipped.** Many teams never leave student-only CRUD.
2. **Feature-oriented Flutter folders** (for student flows) show someone thought about code navigation.
3. **Central `api_endpoints.dart`** is the right instinct (even if backend contracts are noisy).
4. **Language maps on content** is a coherent domain decision, not an afterthought toggle.
5. **Teacher exam workflow** (create → questions → publish rules → analytics) has real product thinking.
6. **Brain/graph tooling in-repo** means care about onboarding agents/humans later — ironic, given how much the code needs that help.

So: not talentless. **Undisciplined.**

---

## Principal engineer summary roast

ACADEMe is what happens when a team with real product ambition meets **tutorial architecture**, **hackathon security**, and **no test culture**, then deploys it with a Docker smile.

The project did not under-scope. It **over-stacked and under-hardened**. It built:

- an LMS tree in Firestore,
- an AI tutor with unauthenticated spend,
- an auth system that forgets what “expiry” means,
- Flutter god-screens that could apply for their own domain name,
- and a test suite that still thinks this is the counter demo.

If this were a PR into a serious education company: **reject**, request security rewrite of auth + AI gate, add tests for auth/progress/exams, split god files, delete dual config/auth fantasies, put OTP in a real store, stop printing secrets, wire or delete dead modules.

If this is a portfolio / early startup: **impressive breadth — now earn the depth.** The product idea is worth it. The current foundation will not survive first contact with real users, real attackers, or a real invoice from Gemini.

---

# Part 4 — Remediation Priorities

Ordered by adult priority:

1. **Fix JWT expiry verification** (`verify_exp` must be true; re-test refresh).
2. **Auth-gate every AI and upload endpoint**; add rate limits.
3. **Stop logging secrets**; fail closed if secrets missing (no default JWT keys).
4. **OTP to Firestore/Redis**; rate-limit send + verify.
5. **One auth story** (Firebase *or* custom JWT — pick, migrate, delete the other).
6. **Delete or mount discussions**; never leave half-APIs lying around.
7. **Tests:** auth, progress write, exam publish rules, at least one agent happy-path with mocked Gemini.
8. **Split 800+ line widgets**; kill singleton controller leakage on logout.
9. **Replace self-HTTP translation** with a direct service call.
10. **Align README with reality** so the next principal doesn’t feel gaslit.

---

# Part 5 — Mental map for future work

| If you need to… | Start here |
|-----------------|------------|
| API / business rules | `ACADEMe-backend/services/` + matching `routes/` |
| AI tutor behavior | `ACADEMe-backend/agents/` + `services/gemini_service.py` |
| Auth / roles | `routes/users.py`, `utils/auth.py`, `app/auth/` |
| Student UI | `lib/app/pages/{homepage,courses,ask_me,progress,topic_details}/` |
| Teacher UI | `lib/app/teacher_panel/` |
| Admin UI | `lib/app/admin_panel/` |
| Wire a new endpoint | Backend route → service → frontend `api_endpoints.dart` + controller |

### Key files cited in this review

| Concern | Path |
|---------|------|
| JWT / current user | `ACADEMe-backend/utils/auth.py` |
| OTP / register / login | `ACADEMe-backend/services/auth_service.py` |
| AI public endpoints | `ACADEMe-backend/main.py` |
| Discussions (unmounted) | `ACADEMe-backend/routes/discussions.py` |
| Cloudinary secret print | `ACADEMe-backend/config/cloudinary_config.py` |
| Self-HTTP translation | `ACADEMe-backend/services/course_service.py` |
| Dual Gemini config | `ACADEMe-backend/configs.py`, `ACADEMe-backend/config/settings.py` |
| Thin “agent” | `ACADEMe-backend/agents/text_agent.py` |
| Auth shell | `ACADEMe-frontend/lib/app/auth/auth_wrapper.dart` |
| Auth client | `ACADEMe-frontend/lib/app/auth/auth_service.dart` |
| API URLs | `ACADEMe-frontend/lib/api_endpoints.dart` |
| Fossil test | `ACADEMe-frontend/test/widget_test.dart` |
---

<br>

# Verification Appendix — Claims Audited Against Source

*Added 2026-07-20. Each claim in the review above was cross-checked against the actual codebase using grep, glob, and direct file reads.*

## Method

- **grep** for pattern searches (`verify_exp`, `CORSMiddleware`, `Depends(get_current_user)`, `except Exception`, emoji sequences)
- **glob** for file discovery (test files, config files, route files)
- **`wc -l`** for widget/file line counts
- **File reads** for line-level evidence of every coded claim

---

## Security (11 claims — 11/11 TRUE, 1 BONUS finding)

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | `verify_exp=False` — tokens never expire | **TRUE** | `utils/auth.py:73,86,112` — all 3 `jwt.decode` calls use `options={"verify_exp": False}`. `ACCESS_TOKEN_EXPIRY=3600` and `REFRESH_TOKEN_EXPIRY=2592000` are written into tokens but never checked. `ExpiredSignatureError` handlers at lines 77 and 103 are dead code. |
| 2 | AI endpoints have no auth | **TRUE** | `main.py:84-188` — zero `Depends(get_current_user)` on any of the 7 `/api/process_*` or `/api/translate_response` endpoints. Grep confirms 63 `Depends(get_current_user)` usages across all route files — none in `main.py`. |
| 3 | Discussion routes unmounted + no auth | **TRUE** | `routes/discussions.py` defines 4 endpoints (`POST /discussions/`, `GET /topics/.../discussions`, etc.). It is neither imported nor included in `main.py:26-57`. Routes also have no `Depends(get_current_user)`. |
| 4 | Default JWT secrets | **TRUE** | `utils/auth.py:19-20` — `os.getenv("JWT_SECRET_KEY", "your_secret_key_here")` and `os.getenv("REFRESH_SECRET_KEY", "your_refresh_secret_key_here")`. If env vars are missing in any deployment, tokens are minted with these literal strings. |
| 5 | Cloudinary secrets to stdout | **TRUE** | `config/cloudinary_config.py:9-11` — `print("CLOUDINARY_CLOUD_NAME:", ...)`, `print("CLOUDINARY_API_KEY:", ...)`, `print("CLOUDINARY_API_SECRET:", ...)`. Executes at module import time. |
| 6 | OTP in process-local dict | **TRUE** | `services/auth_service.py:36-38` — `otp_storage = {}` and `reset_otp_storage = {}`. Process-local `dict`. Lost on restart. Breaks on multi-instance. No rate limit on verify. |
| 7 | Passwords stored in Firestore | **TRUE** | `services/auth_service.py:216` — `db.collection("users").document(user_id).update({"password": hashed_new_password})`. `services/auth_service.py:279` — stores `"password": hashed_password` in new user doc. bcrypt hashes, but coupled with Firestore security rather than Firebase Auth. |
| 8 | Exception messages as API responses | **TRUE** | Pattern `except Exception as e: raise HTTPException(status_code=500, detail=str(e))` appears in 15+ route files (`users.py`, `topics.py`, `quizzes.py`, `ai_recommendations.py`, etc.) and 12+ service files. |
| 9 | No CORS configuration | **TRUE** | Grep for `CORSMiddleware`, `add_middleware`, and `cors` across all backend `.py` files returned zero results. |
| 10 | No rate limiting | **TRUE** | Grep for `ratelimit`, `throttle`, `limiter`, `Throttling` across all backend `.py` files returned zero results. |
| 11 | **BONUS: Firebase custom token endpoint unauthenticated** | **TRUE (not in review)** | `routes/firebase_auth.py:33` — `POST /users/firebase-token` generates Firebase Auth custom tokens for any `user_id` with zero authentication or authorization checks. Anyone can mint tokens for any user. |

---

## Architecture (7 claims — 7/7 TRUE)

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | Dual Gemini configs | **TRUE** | `configs.py` (root) defines `GOOGLE_GEMINI_API_KEY`. `config/settings.py` also defines `GOOGLE_GEMINI_API_KEY`. `services/gemini_service.py` imports from `configs.py` (line 2). `config/settings.py` is not imported by any service — it is dead code. |
| 2 | Admin router double-mounted | **TRUE** | `main.py:30` imports `from routes.admin_teacher_routes import router as admin_teacher_router`. `main.py:54` calls `app.include_router(admin_teacher_router, ...)`. `main.py:55` calls `app.include_router(admin_teacher_routes.router, ...)`. Same router object registered twice under `/api`. |
| 3 | Course creation self-HTTP call | **TRUE** | `services/course_service.py:22` — `url = "http://127.0.0.1:8000/api/translate_response"`. The `translate_text` method makes an HTTP POST to the same FastAPI process instead of calling the translation function directly. Also fails if the server binds to a different host/port or runs behind a proxy. |
| 4 | Thread pool in Firebase service | **TRUE** | `services/firebase_service.py:25` — `self.executor = ThreadPoolExecutor(max_workers=10)`. Used via `loop.run_in_executor(self.executor, fetch_documents)` at lines 102, 123, 149, 181 to wrap synchronous Firestore calls. |
| 5 | "Agents" are thin wrappers | **TRUE** | `agents/text_agent.py` — 10 lines: detect → translate → Gemini response. No agent loop, no tool use, no memory. `image_agent.py` and `document_agent.py` follow the same pattern. |
| 6 | `except Exception` is house style | **TRUE** | 100+ matches across `services/` and `routes/`. Every service file uses bare `except Exception as e:` with `print(f"...{e}")` or `raise HTTPException(status_code=500, detail=str(e))`. |
| 7 | Emoji logging in production services | **TRUE** | `services/course_service.py` uses `🔍`, `🔥`, `⚠️`, `❌`, `📌`. `services/auth_service.py` uses `✅`, `❌`. `services/firebase_service.py` does not use emoji (more restrained). |

---

## Frontend (6 claims — 4/6 TRUE, 2/6 PARTIALLY TRUE)

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | 700-1000 line widgets | **TRUE** | `profile_page.dart` (1021), `teacher_live_classes_screen.dart` (952), `flash_card_widget.dart` (938), `teacher_student_management_screen.dart` (924) exceed 900 lines. 6 more files in 700-800 range (`signup_view.dart` 864, `subtopic.dart` 806, `teacher_profile_screen.dart` 787, `community_chat_screen.dart` 751, `manage_teachers.dart` 750, `home_screen.dart` 717). |
| 2 | Provider + singleton controllers | **TRUE** | `pubspec.yaml:59` — `provider: ^6.1.2`. `main.dart:76-87` — `MultiProvider` with 5 `ChangeNotifierProvider`s. 9 singleton classes found (`ProgressProvider`, `HomeController`, `TopicApiController`, `TopicCacheController`, `AppLifecycleController`, `UserRoleManager`, `CourseDataCache`, `HomeCourseDataCache`, `StudyTimeTracker`). Some singletons (e.g., `HomeController`) are also Provider-managed, creating dual ownership. |
| 3 | Role as raw strings | **TRUE** | `auth_service.dart:178,202-203,242,279-281,341,415,464-466`, `auth_wrapper.dart:79,86-87`, `role.dart:12,26-30,72,80,99`, `signup_view.dart:197,352`, `login_view.dart:89,236` — all compare role via `== 'admin'` / `== 'teacher'` / `== 'student'`. No enum, no constants file. |
| 4 | Emoji debugPrint everywhere | **TRUE** | 298 `debugPrint` calls across 32 files. 111 (37%) contain emoji. Common patterns: ✅ (success), ❌ (error), 🔄 (refresh), ⚠️ (warning), 📡 (API), 🚪 (logout), 🎉 (done), ℹ️ (info). Consistent but noisy. |
| 5 | Two competing localization systems | **PARTIALLY TRUE** | Custom JSON-based `AppLocalizations` (`assets/l10n/*.json`, 6 languages, 642 usages) + `flutter_localizations` for Material widget translations. Complementary, not competing. However, `intl: ^0.20.2` in pubspec is only used for date formatting in 2 files (`pdf_report_service.dart`, `community_chat_screen.dart`) — never for `Intl.message()` localization. ARB files absent. The claim of "competition" is overstated, but the localization story is confused. |
| 6 | Admin panel flat files | **PARTIALLY TRUE** | All 9 files use `Scaffold`+`AppBar` properly — "no proper scaffold" is inaccurate re: Flutter's `Scaffold` widget. But directory structure is flat (`lib/app/admin_panel/` with no `widgets/`/`controllers/`/`screens/` subdirs), business logic inlined in State classes, no named routes, direct `Navigator.push` with hardcoded imports. Student pages (`lib/app/pages/topics/`) have proper subfolder separation. |

---

## Testing (2 claims — 2/2 TRUE)

| # | Claim | Verdict | Evidence |
|---|-------|---------|----------|
| 1 | Backend: no tests | **TRUE** | Grep for `test_` files and `test` directories under `ACADEMe-backend/` returned zero results. |
| 2 | Frontend: only default counter test | **TRUE** | Only test file is `ACADEMe-frontend/test/widget_test.dart` — 30-line boilerplate from `flutter create`. Tests counter widget (`find.text('0')`, `find.text('1')`, `find.byIcon(Icons.add)`) that does not exist in the real `MyApp`. This test would fail if run. |

---

## Accuracy Summary

| Category | Claims | True | Partial | False | Missed |
|----------|--------|------|---------|-------|--------|
| Security | 10 | 10 | 0 | 0 | 1 (Firebase token endpoint) |
| Architecture | 7 | 7 | 0 | 0 | — |
| Frontend | 6 | 4 | 2 | 0 | — |
| Testing | 2 | 2 | 0 | 0 | — |
| **Total** | **25** | **23** | **2** | **0** | **1** |

**The review is substantively correct.** Every coded claim checks out against the real codebase. The F on security and D on code quality are proportionate. The one missed issue (unauthenticated Firebase custom token minting) is the same severity class as the AI endpoints.

*Verification performed by opencode agent against commit `b50dd4d` on 2026-07-20. See `.agents/skills/code-review-and-quality/SKILL.md` and `.agents/skills/ponytail-review/SKILL.md` for methodology.*
