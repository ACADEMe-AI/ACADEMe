# Contributing to ACADEMe

## Contribution Workflow

```
1. Find/Open Issue ──> 2. Branch Off main ──> 3. Make Changes ──> 4. Run graphify update
                                                      │
                                                      v
5. Commit & Push ──> 6. Open PR (use template) ──> 7. Code Review ──> 8. Merge
```

---

## Setting Up Graphify

[Graphify](https://github.com/anomalyco/graphify) turns the codebase into a navigable knowledge graph. Used to understand architecture, find cross-module connections, and maintain context across sessions.

### Install

```bash
pip install graphifyy
# or
uv tool install graphifyy
```

### Generate / Update the Graph

```bash
graphify update .
```

This re-extracts code files (AST-only, no API cost) and updates `graphify-out/`.

### Explore the Graph

```bash
graphify query "How does the AI pipeline work?"
graphify path "TeacherService" "FirebaseService"
graphify explain "Authentication Service"
```

### View Graph Outputs

- `graphify-out/graph.html` — interactive vis.js visualization (open in browser)
- `graphify-out/GRAPH_REPORT.md` — god nodes, communities, surprising connections
- `graphify-out/graph.json` — raw graph data for programmatic access
- `graphify-out/wiki/` — Obsidian vault export (open as vault in Obsidian)

### When to Update

- After adding a new module, service, or route
- After introducing external integrations
- Before starting a task in unfamiliar territory

---

## Using Agent Skills

Skills are in `.agents/skills/` — each is a directory with a `SKILL.md` file. Use them by invoking the `skill` tool with the skill name.

### Built-in Skills (addyosmani/agent-skills)

These 24 skills from [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) are pre-installed:

| Skill | Use When |
|-------|----------|
| `api-and-interface-design` | Designing APIs, module boundaries, public interfaces |
| `browser-testing-with-devtools` | Debugging browser UI, inspecting DOM, network requests |
| `ci-cd-and-automation` | Setting up build/deploy pipelines, CI configuration |
| `code-review-and-quality` | Reviewing code before merging |
| `code-simplification` | Refactoring for clarity without behavior change |
| `context-engineering` | Starting a new session, configuring agent context |
| `debugging-and-error-recovery` | Debugging test failures, build breaks, unexpected errors |
| `deprecation-and-migration` | Removing old systems, migrating users |
| `documentation-and-adrs` | Recording architectural decisions, writing docs |
| `doubt-driven-development` | When correctness matters more than speed |
| `frontend-ui-engineering` | Building production-quality accessible UIs |
| `git-workflow-and-versioning` | Committing, branching, resolving conflicts, releasing |
| `idea-refine` | Refining vague ideas into actionable plans |
| `incremental-implementation` | Implementing features across multiple files |
| `interview-me` | Extracting actual requirements from underspecified asks |
| `observability-and-instrumentation` | Adding logging, metrics, tracing |
| `performance-optimization` | Optimizing frontend, backend, queries, Core Web Vitals |
| `planning-and-task-breakdown` | Breaking specs into ordered tasks |
| `security-and-hardening` | Handling user input, auth, data storage, integrations |
| `shipping-and-launch` | Preparing production launches, pre-launch checklists |
| `source-driven-development` | Grounding decisions in official docs |
| `spec-driven-development` | Creating specs before coding |
| `test-driven-development` | Driving development with tests |
| `using-agent-skills` | Meta-skill for discovering and invoking other skills |

### Project Skill

- `academe-brain` — master context for the ACADEMe project. Contains full architecture, business logic, graph knowledge, and operational protocols. Check this first before any task.

---

## Getting Started for Contributors

1. **Clone the repo** and install backend deps:
   ```bash
   git clone https://github.com/ACADEMe-AI/ACADEMe.git
   cd ACADEMe/ACADEMe-backend
   pip install -r requirements.txt
   ```

2. **Set up environment variables**:
   ```bash
   cp .env.example .env
   # Fill in: FIREBASE_CRED_PATH, GOOGLE_GEMINI_API_KEY, JWT_SECRET_KEY, etc.
   ```

3. **Run the backend**:
   ```bash
   uvicorn main:app --reload
   ```

4. **Run the frontend** (in `ACADEMe-frontend/`):
   ```bash
   flutter pub get
   flutter run
   ```

5. **Install graphify** for codebase navigation:
   ```bash
   uv tool install graphifyy
   graphify update .
   ```

---

## Pull Request Process

1. Use the PR template at `.github/PULL_REQUEST_TEMPLATE.md`
2. Keep changes focused — one feature/fix per PR
3. Update graphify if you add new modules: `graphify update .`
4. Ensure auth flows, API contracts, and multilingual content are not broken
5. Link the relevant issue in the PR description

---

## Code Style

- **Backend:** Follow FastAPI conventions, use Pydantic models for request/response
- **Frontend:** Follow Flutter/Dart conventions, Provider pattern for state
- **General:** No redundant comments, no speculative abstractions
