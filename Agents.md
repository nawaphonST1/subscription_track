# Agent Instructions & Operational Rules

These rules govern all AI Agent interactions and development workflows for this project.

---

## 1. Quick Command Recount Trigger ("1")
- **Trigger**: When the user enters `1` (or asks to review instructions).
- **Behavior**: The agent must immediately reiterate and summarize:
  - All operational rules defined in this document.
  - Current task status, context, and any pending instructions.

---

## 2. Interactive Directives Replay Trigger ("2")
- **Trigger**: When the user enters `2`.
- **Behavior**: The agent must immediately reprint and replay the exact directive block from Section 6 and confirm readiness for the next task.

---

## 3. Server & Application Execution Prohibition
- **Restriction**: The agent must **NEVER** run `npm run start`, `npm start`, `npm run start:dev`, `flutter run`, or any background service start commands.
- **Protocol**: The user will handle starting and running all services manually.

---

## 4. Docker Service Detection & Notification
- **Context**: The user may occasionally forget to start Docker.
- **Protocol**: 
  - If any Docker or database-related command fails because the Docker daemon is not active, do not attempt to start Docker automatically.
  - Immediately notify and remind the user so they can start Docker manually.

---

## 5. E2E (End-to-End) Testing Prohibition
- **Restriction**: Do **NOT** write or execute any E2E tests (they are time-consuming and slow down the iteration cycle).
- **Exception Protocol**: If a critical issue arises where an E2E test is strictly required, the agent must notify the user and obtain explicit confirmation before creating or running any E2E tests.

---

## 6. Execution Protocol & Core Workflow
1. **Error Post-Mortem & Continuous Improvement:**
   - Summarize encountered errors, root causes, and concrete corrective actions directly in the summary step.
2. **Resource Constraint Guardrails:**
   - Monitor system resources closely. If memory (RAM), disk space, or compute bottlenecks occur, **HALT execution immediately** and notify the user with the specific failure state, memory dump/status, and recommended resolution before proceeding.
3. **Autonomous Execution:**
   - Pre-configure all required runtime parameters, flags, and configuration files to run tasks autonomously without asking permission beforehand. Avoid interactive prompts or confirmations (e.g., auto-submit, non-interactive CLI flags like `-y`, `--yes`, or headless mode defaults).
   - After completing tasks, provide a thorough, structured report summarizing all executed commands, findings, and results to the user.
4. **Assessment Accuracy Over Points (No Over-Optimization):**
   - When provided with lab "ASSESSMENT", "DELIVERABLES", or grading criteria, do **NOT** worry about points or score chasing. The objective is simply to fulfill the **ASSESSMENT requirements accurately and correctly**.
   - Do **NOT** attempt to autonomously generate screenshots, create mock deliverable files, or run exhaustive hidden background tests to artificially ensure a 100% pass rate.
   - The agent's responsibility is solely to write the correct code/configuration required by the lab. Verifying the assessment and gathering deliverables is strictly the user's responsibility.

---

## 7. Division of Labor & Terminal Usage
- **AI Role**: Focus strictly on processing logic, planning, and writing/editing code or configuration files.
- **User Role**: Environment setup, package installation, running builds, Docker management, and executing terminal commands.
- **Data Gathering & Terminal Constraint**:
  - **Allowed**: The agent is freely allowed to read static project files and explore the repository's code structure.
  - **Must Ask First**: Before attempting to check running processes (e.g., active Node instances), investigate background tasks, execute long-running terminal commands, or perform heavy repository scans, the agent MUST ask the user first. The agent should also prioritize asking the user directly for context, as the user might already know the answer.

---

## 8. Branch Constraint
- **Restriction**: All project/lab work must strictly occur on the `jenkins-lab-nawaphon` branch.
- **Protocol**: If external lab instructions dictate switching to a different branch, the agent must halt and notify the user instead of executing the branch change.

---

## 9. Proven & Verified Implementation Requirement
- **Mandate**: The agent must strictly use verified, proven, and battle-tested solutions that are confirmed to work.
- **Protocol**:
  - Do NOT guess URLs, version tags, flags, or speculative workarounds that lead to trial-and-error iteration cycles.
  - Always verify official specifications, URLs, tool parameters, and binary compatibility before proposing or editing configurations.
  - Prioritize standard, robust, deterministic, and minimal-dependency approaches over experimental or unverified implementations.

---

## 10. Non-Regression & Working State Preservation
- **Strict Mandate**: The agent must **NEVER break, degrade, or introduce errors into existing features, stages, or configurations that are already working**.
- **Protocol**:
  - Treat all previously working pipeline stages, scripts, and application logic as invariant baselines.
  - When introducing new stages, features, or fixes, do NOT alter or compromise existing working behavior.
  - Always verify backward compatibility with existing project configurations before applying changes.


