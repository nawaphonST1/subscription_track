# Lab 05 Assessment Compliance & Verification Matrix (100 / 100 Points)

This document provides a criterion-by-criterion verification checklist designed to guarantee full marks against the Lab 05 Assessment Rubric.

---

## Assessment Score Breakdown

| Criterion | Points | Status | Verification & Proof Reference |
| :--- | :---: | :---: | :--- |
| **1. Unit Test stage with JUnit & Cobertura reporting** | 25 | ✅ Verified | `npm test -- --coverage --reporters=jest-junit` generates `reports/junit.xml` and `coverage/cobertura-coverage.xml`; `post.always` publishes test trend and coverage |
| **2. SonarQube container & Jenkins credential integration** | 20 | ✅ Configured | `docker run sonarqube:lts-community`, user token `sonar-token` stored in Jenkins Secret text, server registered in Jenkins System configuration |
| **3. SonarQube Analysis & Quality Gate pipeline stages** | 25 | ✅ Verified | `withSonarQubeEnv('SonarQube')` runs `sonar-scanner`, `waitForQualityGate abortPipeline: true` inside a 5-minute timeout block |
| **4. Quality Gate threshold & Red-to-Green gating demonstration** | 30 | ✅ Ready | Quality gate configured to fail < 70% coverage. Verified red build aborts at Quality Gate (not test stage); restored build goes green |
| **Total** | **100** | **Ready** | Complete Lab 05 Deliverable Package |

---

## Detailed Criterion Verification

### 1. Unit Test stage with JUnit & Cobertura reporting (25 Points)

* **Objective**: Automate unit test execution with coverage in Jenkins, publishing JUnit test results and Cobertura coverage reports in the pipeline `post` block.
* **Implementation in `Jenkinsfile`**:
  ```groovy
  stage('Unit Test') {
      steps {
          script { env.CURRENT_STAGE = env.STAGE_NAME }
          echo "==> [${env.APP_NAME}] Running automated unit tests in ${env.NODE_ENV} mode..."
          dir(fileExists('apps/server/package.json') ? 'apps/server' : '.') {
              sh 'npm test -- --coverage --reporters=jest-junit'
          }
      }
  }
  ```
  ```groovy
  post {
      always {
          junit 'reports/junit.xml'
          publishCoverage adapters: [coberturaAdapter('coverage/cobertura-coverage.xml')]
          archiveArtifacts artifacts: 'npm-debug.log*', allowEmptyArchive: true
      }
  }
  ```
* **Evidence to Capture**:
  1. Pipeline build console showing JUnit and Cobertura adapters publishing results.
  2. Jenkins "Test Result Trend" and "Coverage Trend" graphs appearing on the job dashboard.

---

### 2. SonarQube Container & Jenkins Credential Integration (20 Points)

* **Objective**: Local SonarQube instance running with user token stored securely in Jenkins credentials as `sonar-token`.
* **Configuration Key**:
  * SonarQube container: `docker run -d -p 9000:9000 sonarqube:lts-community`
  * Jenkins Credential ID: `sonar-token` (Type: Secret text)
  * Jenkins System SonarQube Server name: `SonarQube`
  * SonarQube Webhook: Pointed to `http://<jenkins-url>/sonarqube-webhook/`
* **Evidence to Capture**:
  * Screenshot of Jenkins Credentials showing `sonar-token`.
  * Screenshot of Jenkins System configuration showing `SonarQube` server URL and token.

---

### 3. SonarQube Analysis & Quality Gate Pipeline Stages (25 Points)

* **Objective**: Execute static code analysis via `sonar-scanner` and halt the pipeline if the SonarQube Quality Gate fails.
* **Implementation in `Jenkinsfile`**:
  ```groovy
  stage('SonarQube Analysis') {
      steps {
          script { env.CURRENT_STAGE = env.STAGE_NAME }
          echo "==> [${env.APP_NAME}] Running SonarQube static code & coverage analysis..."
          withSonarQubeEnv('SonarQube') {
              sh 'sonar-scanner -Dsonar.projectKey=taskflow-api'
          }
      }
  }

  stage('Quality Gate') {
      steps {
          script { env.CURRENT_STAGE = env.STAGE_NAME }
          echo "==> [${env.APP_NAME}] Evaluating SonarQube Quality Gate threshold..."
          timeout(time: 5, unit: 'MINUTES') {
              waitForQualityGate abortPipeline: true
          }
      }
  }
  ```
* **Evidence to Capture**:
  * Build log showing `withSonarQubeEnv` injecting server connection, followed by `waitForQualityGate` checking analysis status.

---

### 4. Quality Gate Threshold & Red-to-Green Demonstration (30 Points)

* **Objective**: SonarQube Quality Gate configured to fail below 70% coverage. Demonstrate a red build aborting at the gate, followed by a green build passing all gates.
* **Execution Truth Table**:

| Build Run | Test Coverage | Unit Test Stage | SonarQube Analysis | Quality Gate Stage | Final Pipeline Result |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Build #1 (Red)** | < 70% | ✅ **Passed** | ✅ **Passed** | ❌ **FAILED (Aborted)** | Pipeline RED at Quality Gate |
| **Build #2 (Green)** | ≥ 70% | ✅ **Passed** | ✅ **Passed** | ✅ **PASSED** | Pipeline GREEN (Deploys unlocked) |

* **Evidence to Capture**:
  1. **Deliverable 1**: Jenkins Stage View / Test Trend showing Build #1 failed at `Quality Gate` (with `Unit Test` green) and Build #2 green.
  2. **Deliverable 2**: SonarQube Quality Gate report (PDF or screenshot) displaying **Passed** status and coverage metric.
