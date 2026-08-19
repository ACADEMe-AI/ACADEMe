# ACADEMe Mobile — Unique Selling Propositions

## Platform Identity
ACADEMe is a **multilingual, AI-tutored learning platform** for class-based K-12 schools and institutions. It combines an LMS, an AI tutor, teacher ops tools, and admin controls in a single mobile-first application.

---

## Core USPs

### 1. Multilingual by Design
Every content node stores translations in 7 languages (en/fr/es/de/zh/ar/hi) automatically. Students see content in their chosen language without manual duplication. The AI tutor detects input language, translates through English for processing, and responds in the student's target language.

**Why it matters:** Schools with linguistically diverse classrooms get one platform, not one per language.

---

### 2. ASKMe — Multimodal AI Tutor
A single chat interface accepts text, images, audio, video, and documents. Backend pipelines detect language, translate, process through Gemini 2.0 Flash, and translate back. Supports:
- Text Q&A
- Image analysis (diagrams, handwritten problems)
- Document analysis (PDF, DOCX, TXT)
- Audio transcription + analysis
- Video analysis

**Why it matters:** Students don't switch tools for different media types. One chat does everything.

---

### 3. Role-Native Architecture
Three distinct experiences in one app:

| Role | Sees | Can Do |
|------|------|--------|
| **Student** | Courses, ASKMe, flashcards, quizzes, progress charts, community chat | Learn, ask questions, track progress |
| **Teacher** | Own courses, live classes, exams, student analytics | Create content, teach, assess |
| **Admin** | Teacher management, full course hierarchy CRUD | Orchestrate the platform |

Each role gets a purpose-built shell, not the same app with toggles.

---

### 4. Class-Based Content Filtering
Students see only courses assigned to their class. Teachers manage content for their allotted classes. Admins assign teachers to classes. The entire platform respects this boundary — a student in Grade 8-A never sees Grade 10 content.

**Why it matters:** Schools need class boundaries. This isn't a MOOC where everyone sees everything.

---

### 5. Hierarchical Content Engine
```
Course
 └─ Topic
     ├─ Materials (text / image / video / audio / document)
     ├─ Quizzes → Questions
     └─ Subtopics
         ├─ Materials
         └─ Quizzes → Questions
```

Unlimited depth. Each node carries its own 7-language map. Students consume, get assessed, and get AI help at every level.

**Why it matters:** Structured pedagogy maps naturally to this tree. Teachers organize once; students navigate freely.

---

### 6. Dual Exam System (Teacher-Owned)
Teachers create exams with mixed question types:
- **MCQ** — multiple choice with correct answer tracking
- **Subjective** — open-ended with rubric support

Publish/unpublish workflow. Student submissions collected. Analytics: score distribution (excellent/good/average/below), pass rates, per-question breakdown.

**Why it matters:** Real schools need real exams — not just quizzes. Both formative (quizzes) and summative (exams) are covered.

---

### 7. Live Class Management
Teachers schedule classes with meeting platform link, start/stop flow, and recording sharing. Students see upcoming and recorded sessions.

**Why it matters:** Hybrid learning needs a schedule, not just a Zoom link in a chat.

---

### 8. Progress Everywhere
Every action — reading a material, attempting a quiz, watching a video — generates a progress event. Students see:
- Study time tracking (weekly, per topic)
- Completion rates per topic/subtopic
- Quiz scores and timelines
- Visual charts (hero graph, score timeline)

Teachers see aggregate class analytics. Admins see institution-wide stats.

**Why it matters:** Progress is granular enough for a student to see "I scored 60% on Algebra Quiz 3" and aggregated enough for a principal to see "Grade 9 is at 72% average completion."

---

### 9. AI-Powered Recommendations
Gemini analyzes a student's progress data (completed materials, quiz scores, topics visited) and generates personalized recommendations: "You're strong in Algebra but behind in Geometry — here are 3 materials to review."

**Why it matters:** One-size-fits-all course delivery ignores individual gaps. AI recommendations fill them without teacher intervention.

---

### 10. Teacher Analytics Suite
Per-class dashboards showing:
- Active student count
- Average progress completion rate
- Per-student detailed analytics (materials read, quiz scores, time spent)
- Class progress overview with student-level summary

**Why it matters:** Teachers don't need raw data — they need answers to "who's falling behind and where."

---

### 11. Admin Teacher Lifecycle
Admins can:
- Add teachers (create profile + assign classes + set role)
- Remove teachers (deactivate + reassign students)
- Update teacher details
- View comprehensive stats (subjects taught, class distribution, content created, student counts)

**Why it matters:** Schools have teacher turnover. Admin controls prevent orphaned classes and lost access.

---

### 12. Admin Dashboard Intelligence
Institution-wide analytics:
- Performance distribution (how many teachers are high/medium/low performing)
- Class coverage (which classes have teachers assigned)
- Subject-wise breakdown
- Top 10 teachers by metrics
- Monthly activity trends

**Why it matters:** A principal should see the health of the institution in one screen, not 20 spreadsheets.

---

### 13. Dual Auth: Firebase + Custom JWT
Users can authenticate via:
- Firebase Auth (Google Sign-In, email link)
- Custom JWT (email/password with bcrypt verification)

OTP verification for registration via email. Token refresh flow. Role assignment on login.

**Why it matters:** Schools have different auth preferences. Some want Google SSO; others want school-managed credentials.

---

### 14. Community Chat (Scaffolded)
Firebase Realtime Database chat rooms. Custom token authentication. Discussion threads per topic. Backend service exists.

**Why it matters:** Peer learning and study groups are proven pedagogy. The scaffold is built; wiring into main.py connects it.

---

### 15. Cloudinary Media Pipeline
All uploaded media (images, videos, audio, documents) are processed through Cloudinary CDN with auto-resource-type detection. Secure URLs returned. Material previews in-app.

**Why it matters:** Schools don't manage file storage. Upload once; access everywhere with CDN speed.

---

## Feature Count Summary

| Category | Features |
|----------|----------|
| Student learning | Courses, topics, subtopics, materials, flashcards, quizzes, ASKMe, progress |
| Student support | Progress visuals, AI recommendations, community chat, study time tracking, profile |
| Teacher tools | Courses, live classes, exams (MCQ + subjective), student analytics |
| Admin tools | Teacher lifecycle, course CRUD, dashboard analytics |
| Platform | Multilingual (7 languages), dual auth, class filtering, Cloudinary media, role-based routing |
| AI | Text, image, audio, video, document agents; Gemini 2.0 Flash; Whisper STT; LibreTranslate |
| **Total features** | **~30+ distinct user-facing features** |

---

## What ACADEMe Is Not

- Not a MOOC — class-bound, institution-focused
- Not a single-user app — three-role architecture
- Not English-only — 7 languages with auto-translation
- Not just quizzes — full exam system with subjective grading
- Not just AI chat — structured LMS with AI augmentation
- Not a prototype — feature-complete across student/teacher/admin flows