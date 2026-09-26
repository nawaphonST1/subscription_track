# Agent Instructions & Operational Rules

These rules govern all AI Agent interactions and development workflows for this project.

---

## 1. Quick Command Recount Trigger ("1")
- **Trigger**: When the user enters `1` (or asks to review instructions).
- **Behavior**: The agent must immediately reiterate and summarize:
  - All operational rules defined in this document.
  - Current task status, context, and any pending instructions.

---

## 2. Server & Application Execution Prohibition
- **Restriction**: The agent must **NEVER** run `npm run start`, `npm start`, `npm run start:dev`, `flutter run`, or any background service start commands.
- **Protocol**: The user will handle starting and running all services manually.

---

## 3. Docker Service Detection & Notification
- **Context**: The user may occasionally forget to start Docker.
- **Protocol**: 
  - If any Docker or database-related command fails because the Docker daemon is not active, do not attempt to start Docker automatically.
  - Immediately notify and remind the user so they can start Docker manually.

---

## 4. E2E (End-to-End) Testing Prohibition
- **Restriction**: Do **NOT** write or execute any E2E tests (they are time-consuming and slow down the iteration cycle).
- **Exception Protocol**: If a critical issue arises where an E2E test is strictly required, the agent must notify the user and obtain explicit confirmation before creating or running any E2E tests.

---

## 5. Autonomous Terminal Command Execution & Post-Execution Reporting
- **Authorization**: The agent is permitted to run all required terminal commands (inspections, configurations, file operations, builds, unit tests, and CI/CD operations) autonomously without asking the user for confirmation beforehand.
- **Autonomous Workflow**: Proceed through the complete workflow independently to resolve tasks.
- **Post-Execution Reporting**: After finishing the tasks, provide a thorough, structured report summarizing all executed commands, findings, and results to the user.
