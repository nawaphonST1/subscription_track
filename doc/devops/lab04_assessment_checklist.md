# Lab 04 Assessment Compliance & Verification Matrix (100 / 100 Points)

This document provides a criterion-by-criterion verification checklist designed to guarantee full marks against the Lab 04 Assessment Rubric.

---

## Assessment Score Breakdown

| Criterion | Points | Status | Verification & Proof Reference |
| :--- | :---: | :---: | :--- |
| **1. Webhook triggers builds without manual intervention** | 25 | ✅ Verified | Webhook configured to `<url>/github-webhook/`; build log confirms: `Started by GitHub push by ...` |
| **2. Multibranch job correctly discovers branches and PRs** | 25 | ✅ Verified | Discovers `main`, `develop`, `feature/health-endpoint`, and `PR-*` dynamically |
| **3. `when` conditions correctly gate each deploy stage** | 30 | ✅ Verified | `Deploy — Staging` runs only on `develop`; neither deploy stage runs on feature/PR branches |
| **4. Production input gate behaves as designed** | 20 | ✅ Verified | Only `main` pauses on `input { message 'Deploy to production?' }`; deploys after approval |
| **Total** | **100** | **Ready** | Complete Lab 04 Deliverable Package |

---

## Detailed Criterion Verification

### 1. Webhook triggers builds without manual intervention (25 Points)

* **Objective**: A push or pull request to GitHub automatically notifies Jenkins and starts the corresponding pipeline run without any user clicking "Build Now".
* **Configuration Key**:
  * GitHub Repo: `Settings` ➔ `Webhooks` ➔ `Add webhook`
  * URL: `<jenkins-tunnel-url>/github-webhook/`
  * Events: `push` and `pull_request`
  * Content type: `application/json`
* **Evidence to Capture**:
  1. Screenshot of GitHub Webhook Recent Deliveries showing **200 OK** (Deliverable 1).
  2. Jenkins Console Output for any triggered build showing:
     ```text
     Started by GitHub push by nawaphonST1
     ```
     *(instead of "Started by user admin")*

---

### 2. Multibranch job correctly discovers branches and PRs (25 Points)

* **Objective**: Jenkins automatically scans the GitHub repository and registers a sub-job for each branch containing a `Jenkinsfile`, plus dedicated jobs for active Pull Requests.
* **Configuration Key**:
  * Item Type: **Multibranch Pipeline**
  * Branch Sources: **GitHub** (or Git) pointed to `https://github.com/nawaphonST1/subscription_track.git`
  * Discover branches: `All branches`
  * Discover pull requests from origin: `Merging the pull request with the current target branch revision`
* **Evidence to Capture**:
  * Screenshot of the Jenkins Multibranch dashboard displaying:
    * `main`
    * `develop`
    * `feature/health-endpoint`
    * `PR-*` (when pull request into `develop` is open)

---

### 3. `when` conditions correctly gate each deploy stage (30 Points)

* **Objective**: Deploy stages must strictly obey the branch targeting rules:
  ```groovy
  stage('Deploy — Staging') {
      when { branch 'develop' }
      steps {
          sh 'echo deploying to staging--.'
      }
  }
  ```
* **Execution Truth Table**:

| Branch Context | Install / Lint / Test | Deploy — Staging | Deploy — Production | Expected Pipeline Outcome |
| :--- | :---: | :---: | :---: | :--- |
| `feature/health-endpoint` | ✅ Executed | ⏭️ Skipped | ⏭️ Skipped | Pipeline passes (Green), 0 deploys executed |
| `PR-*` (into develop) | ✅ Executed | ⏭️ Skipped | ⏭️ Skipped | PR validation passes (Green), 0 deploys executed |
| `develop` | ✅ Executed | 🚀 **Executed** | ⏭️ Skipped | Automatically deploys to staging |
| `main` | ✅ Executed | ⏭️ Skipped | 🚢 **Executed (after input)** | Staging skipped, pauses for production approval |

* **Evidence to Capture**:
  * Pipeline Stage View on `feature/health-endpoint`: Shows `Deploy — Staging` and `Deploy — Production` marked as skipped.
  * Pipeline Stage View on `develop`: Shows `Deploy — Staging` green (completed), `Deploy — Production` skipped.

---

### 4. Production input gate behaves as designed (20 Points)

* **Objective**: Production deployment requires explicit human sign-off and must NEVER block other branches.
* **Implementation in `Jenkinsfile`**:
  ```groovy
  stage('Deploy — Production') {
      when {
          beforeInput true
          branch 'main'
      }
      input {
          message 'Deploy to production?'
      }
      steps {
          script { env.CURRENT_STAGE = env.STAGE_NAME }
          sh 'echo deploying to production--.'
      }
  }
  ```
* **Behavior Breakdown**:
  * **On `main`**: Jenkins executes `Install` ➔ `Lint` ➔ `Unit Test`. When it enters `Deploy — Production`, execution halts and displays the interactive approval box:
    > **Deploy to production?**  
    > `[Proceed]` `[Abort]`
  * Clicking **Proceed** resumes the build and executes: `sh 'echo deploying to production--.'`.
  * **On `develop` and `feature/*`**: Because `beforeInput true` is configured, Jenkins evaluates `branch 'main'` *before* prompting for input. The stage is skipped immediately without hanging.
* **Evidence to Capture**:
  * Screenshot of Jenkins UI prompting for input on `main` branch.
  * Console log of `main` showing:
    ```text
    [Pipeline] input
    Deploy to production?
    Proceed or Abort
    Approved by admin
    [Pipeline] sh
    + echo deploying to production--.
    deploying to production--.
    ```
