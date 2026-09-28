# Lab 05 — Automated Testing & Quality Gates Guide

Comprehensive step-by-step implementation guide for **Lab 05: Automated Testing & Quality Gates** (Deck 09: Automated Testing in Jenkins).

---

## 1. Overview & Objectives

In modern CI/CD pipelines, automated testing is only as effective as the feedback loop and quality gates built around it. A test that runs silently without persistent reporting does not protect against regressions.

**Lab 05 Goals:**
1. **JUnit & Coverage Reporting:** Run automated unit tests with coverage, publishing JUnit-format test results and Cobertura coverage trend graphs directly in Jenkins.
2. **SonarQube Integration:** Stand up a SonarQube instance, integrate with Jenkins via `withSonarQubeEnv`, and run static code and coverage analysis (`sonar-scanner`).
3. **Quality Gate Enforcement:** Enforce an automated Quality Gate (`waitForQualityGate abortPipeline: true`) that halts the pipeline if coverage falls below 70%.
4. **Validation of Gates:**
   - **Build 1 (Red Gate):** Deliberately reduce test coverage below 70% and verify that the pipeline fails at the `Quality Gate` stage (while `Unit Test` succeeds).
   - **Build 2 (Green Gate):** Restore test coverage above 70% and verify that the entire pipeline passes.

---

## 2. Infrastructure Setup: SonarQube & Jenkins Integration

> [!NOTE]
> Per project operational rules, all servers and background services must be started manually by the user. Ensure your Docker Desktop daemon is running before proceeding.

### Step 2.1 — Run Local SonarQube Container

Execute the following command in PowerShell / Terminal:
```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
```

Verify that SonarQube is up:
- Open your browser to: `http://localhost:9000`
- Default login:
  - Username: `admin`
  - Password: `admin`
- Set a new password when prompted (e.g., `admin123` or your preferred password).

---

### Step 2.2 — Generate SonarQube Project & User Token

1. In SonarQube (`http://localhost:9000`):
   - Click on your profile avatar (top-right) ➔ **My Account** ➔ **Security** tab.
   - Under **Generate Token**:
     - Name: `sonar-token`
     - Type: **User Token** (or **Global Analysis Token**)
     - Expires in: **30 days** (or Never)
   - Click **Generate**.
   - **Copy the generated token string** (you will not be able to view it again).

---

### Step 2.3 — Configure SonarQube Webhook (Crucial for `waitForQualityGate`)

For `waitForQualityGate` to unblock in Jenkins, SonarQube must notify Jenkins when analysis processing completes:

1. In SonarQube: Go to **Administration** ➔ **Configuration** ➔ **Webhooks**.
2. Click **Create**:
   - **Name**: `Jenkins Webhook`
   - **URL**: `http://<your-jenkins-ip-or-host>:8080/sonarqube-webhook/`  
     *(If Jenkins runs in Docker on the same machine, use `http://host.docker.internal:8080/sonarqube-webhook/`)*
3. Click **Create**.

---

### Step 2.4 — Configure Jenkins Credentials & System Settings

1. **Add Credential:**
   - In Jenkins: Navigate to **Manage Jenkins** ➔ **Credentials** ➔ **System** ➔ **Global credentials (unrestricted)** ➔ **Add Credentials**.
   - **Kind**: `Secret text`
   - **Secret**: Paste the token copied from Step 2.2.
   - **ID**: `sonar-token`
   - **Description**: `SonarQube Analysis Token`
   - Click **Create**.

2. **Configure SonarQube Server in Jenkins:**
   - In Jenkins: Navigate to **Manage Jenkins** ➔ **System** (or **Configure System**).
   - Scroll to **SonarQube servers**:
     - Check **Enable injection of SonarQube server configuration as environment variables**.
     - Click **Add SonarQube**:
       - **Name**: `SonarQube` *(must match `withSonarQubeEnv('SonarQube')` in `Jenkinsfile`)*
       - **Server URL**: `http://host.docker.internal:9000` (or `http://localhost:9000` if Jenkins runs natively on the host)
       - **Server authentication token**: Select `sonar-token` from the dropdown.
   - Click **Save**.

3. **Install Required Jenkins Plugins** (if not already installed):
   - **JUnit Plugin**: For rendering `reports/junit.xml` test result graphs.
   - **Code Coverage API Plugin** / **Cobertura Plugin**: For rendering coverage trend graphs.
   - **SonarQube Scanner Plugin**: For `withSonarQubeEnv` and `waitForQualityGate`.

---

## 3. Configure SonarQube Quality Gate Threshold (70%)

1. In SonarQube: Navigate to **Quality Gates** in the top navigation bar.
2. Select the active Quality Gate (e.g., **Sonar way**) or click **Create** to create a custom gate named `Taskflow Gate`.
3. Under **Conditions on Overall Code**:
   - Click **Add Condition**.
   - Metric: **Coverage**
   - Condition: **is less than**
   - Value: `70%`
   - Click **Add**.
4. Set this Quality Gate as default, or navigate to **Project Settings** ➔ **Quality Gate** inside project `taskflow-api` and assign it.

---

## 4. Pipeline Configuration Architecture

### 4.1 Test Runner (`apps/server/run-tests.mjs`)
To seamlessly bridge the lab requirement (`npm test -- --coverage --reporters=jest-junit`) with Vitest v8 coverage:
- Intercepts `--reporters=jest-junit` and `--coverage` flags.
- Produces `reports/junit.xml` via Vitest's built-in JUnit reporter.
- Generates Cobertura (`coverage/cobertura-coverage.xml`), LCOV (`coverage/lcov.info`), and text reports.
- Automatically synchronizes output files to the workspace root so `junit 'reports/junit.xml'` and `publishCoverage adapters: [coberturaAdapter('coverage/cobertura-coverage.xml')]` resolve with 100% reliability.

### 4.2 SonarQube Scanner Configuration (`sonar-project.properties`)
```properties
sonar.projectKey=taskflow-api
sonar.projectName=taskflow-api
sonar.projectVersion=1.0.0
sonar.sources=apps/server/src
sonar.tests=apps/server/test,apps/server/src
sonar.test.inclusions=**/*.spec.ts,**/*.test.ts
sonar.exclusions=**/node_modules/**,**/dist/**,**/coverage/**,**/reports/**,**/*.spec.ts
sonar.javascript.lcov.reportPaths=apps/server/coverage/lcov.info,coverage/lcov.info
sonar.testExecutionReportPaths=apps/server/reports/junit.xml,reports/junit.xml
```

### 4.3 Pipeline Stages in `Jenkinsfile`
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

post {
    always {
        junit 'reports/junit.xml'
        publishCoverage adapters: [coberturaAdapter('coverage/cobertura-coverage.xml')]
        archiveArtifacts artifacts: 'npm-debug.log*', allowEmptyArchive: true
    }
}
```

---

## 5. Executing Deliverables: Red vs Green Builds

### 5.1 Producing the Red Build (Failing at Quality Gate)

1. Temporarily isolate or skip test suites to drop coverage below 70%.  
   For example, in `apps/server/run-tests.mjs`, temporarily target a minimal test suite:
   ```javascript
   vitestArgs.push('src/swagger'); // Only runs swagger tests, lowering overall project coverage
   ```
2. Commit and push the branch, or trigger the Jenkins build.
3. Observe Jenkins Pipeline execution:
   - `Install`: ✅ Passes.
   - `Lint`: ✅ Passes.
   - `Unit Test`: ✅ **Passes** (all executed tests succeed; reports published).
   - `SonarQube Analysis`: ✅ Passes (scans project and uploads coverage < 70%).
   - `Quality Gate`: ❌ **Fails & Aborts** (`QUALITY GATE STATUS: FAILED`).
4. **Capture Evidence**: Screenshot the Jenkins Stage View showing `Quality Gate` red and `Unit Test` green.

---

### 5.2 Producing the Green Build (Passing all Gates)

1. Restore full test coverage (revert the temporary filter so all unit test suites run):
   ```javascript
   vitestArgs.push('src'); // Runs all unit test suites
   ```
2. Commit, push, and trigger the Jenkins build.
3. Observe Jenkins Pipeline execution:
   - `Install`: ✅ Passes.
   - `Lint`: ✅ Passes.
   - `Unit Test`: ✅ Passes with high coverage (> 70%).
   - `SonarQube Analysis`: ✅ Passes.
   - `Quality Gate`: ✅ **Passes** (`QUALITY GATE STATUS: PASSED`).
   - `Deploy — Staging` / `Deploy — Production`: Proceed according to branch rules.
4. **Capture Evidence**:
   - Jenkins Test Result Trend graph showing the transition from red build to green build.
   - SonarQube Quality Gate dashboard report showing **Passed** status and coverage metric.

---

## 6. Summary of Rule Compliance

- **Rule 3 (Server Prohibition)**: No servers or background processes (`npm start`, `flutter run`) were started by the agent. Local container commands are documented for manual user execution.
- **Rule 4 (Docker Detection)**: Docker run instructions provided clearly; user handles daemon startup.
- **Rule 5 (E2E Testing Prohibition)**: Explicit user confirmation requested via interactive prompt; user elected to omit Playwright E2E tests, strictly adhering to the prohibition.
