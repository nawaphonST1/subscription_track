# Lab 06 Assessment Checklist & Screenshot Guide

This guide details exactly where to look in the Jenkins UI, what to screenshot, and what technical explanation to write for each criterion.

---

## Criterion 1: Correct Stage Order (25 Points)
**Order Requirement**: `Secrets Detection` → `SAST` → `SCA — npm audit` → `Generate SBOM` → `Policy Gate`

### Where to Screenshot:
- Open Jenkins at `http://localhost:8080/job/multibranch_jenkins-lab-nawaphon/`.
- In **Pipeline Stage View** / **Ocean Blue**, capture the stage progression across the top:
  1. `Install`
  2. `Secrets Detection`
  3. `SAST`
  4. `SCA — npm audit`
  5. `Generate SBOM`
  6. `Policy Gate`
  7. `Unit Test`
  8. `SonarQube Analysis`
  9. `Quality Gate`

### Technical Explanation:
> The pipeline strictly adheres to the shift-left security paradigm. High-entropy secret leaks and static security anti-patterns are evaluated before packaging or building dependencies. The stages execute in the prescribed sequence: Gitleaks secrets detection precedes SAST (ESLint security & Semgrep), followed by SCA dependency auditing, CycloneDX SBOM generation, and OPA/Rego policy gate validation before build artifacts and test execution proceed.

---

## Criterion 2: Fail/Warn Threshold Logic (25 Points)
**Requirement**: Non-zero exit code does not fail the build blindly; fails ONLY if critical vulnerabilities > 0, warns otherwise.

### Where to Screenshot:
- Expand stage **`SCA — npm audit`** in the Jenkins build console log.
- Capture the log snippet showing:
```text
[Pipeline] { (SCA — npm audit)
==> [taskflow-api] Running SCA dependency audit with fail/warn threshold...
...
SCA passed with 0 critical vulnerabilities (warnings allowed)
```

### Technical Explanation:
> Instead of using naive exit-code gating (`npm audit` exits non-zero whenever high or moderate vulnerabilities exist), the pipeline captures the audit JSON and queries `.metadata.vulnerabilities.critical` via `jq`. Non-critical (low, moderate, high) findings produce warnings in the build log, while any critical vulnerability immediately triggers `error(...)`, ensuring a balanced fail/warn threshold policy.

---

## Criterion 3: SBOM Generated, Signed, and Archived (25 Points)
**Requirement**: CycloneDX SBOM emitted via Syft, signed with Cosign keypair, and archived as pipeline build artifacts.

### Where to Screenshot:
- In the Jenkins Build Summary page (e.g. Build #12), inspect the **Build Artifacts** section:
  - `taskflow-api.cdx.json`
  - `taskflow-api.cdx.json.sig`
  - `cosign.pub`
- In the **Generate SBOM** stage console log, show:
```text
Private key written to cosign.key
Public key written to cosign.pub
Using payload from: taskflow-api.cdx.json
Wrote signature to file taskflow-api.cdx.json.sig
Verified OK
```

### Technical Explanation:
> The pipeline utilizes Anchore Syft to catalog direct and transitive dependencies into an industry-standard CycloneDX SBOM (`taskflow-api.cdx.json`). An ephemeral local keypair is generated via Cosign to cryptographically sign the SBOM (`taskflow-api.cdx.json.sig`), followed by an in-pipeline signature verification check confirming cryptographic authenticity (`Verified OK`) before archiving both artifacts to the Jenkins release store.

---

## Criterion 4: Policy Gate Demonstrably Blocks and Un-Blocks Correctly (25 Points)
**Requirement**: `policy/security.rego` blocks builds when CRITICAL CVE is detected, and un-blocks when resolved.

### Where to Screenshot:
1. **Blocked Demonstration Log**:
   - Console log showing Policy Gate evaluation failure:
```text
[Pipeline] { (Policy Gate)
==> [taskflow-api] Evaluating OPA Rego security policy (policy/security.rego)...
[Pipeline] error
Policy Gate Blocked build due to security policy violations:
["Dependency scan reported 1 CRITICAL vulnerability (threshold: 0 allowed)", "Package 'vulnerable-pkg' has CRITICAL severity vulnerability"]
```
2. **Passing Demonstration Log**:
   - Console log showing clean policy evaluation:
```text
[Pipeline] { (Policy Gate)
==> [taskflow-api] Evaluating OPA Rego security policy (policy/security.rego)...
✅ Policy Gate PASSED: No CRITICAL vulnerabilities violate policy/security.rego
```

### Technical Explanation:
> The Open Policy Agent evaluates `policy/security.rego` against the dependency audit dataset. When a dependency downgrade introduces a CRITICAL CVE, Clause 2 triggers, populating `data.security.deny` and falsifying `data.security.allow`, halting the pipeline before build stages. Once the vulnerable package is upgraded or removed, Clause 1 evaluates to true (`count(deny) == 0`), allowing the pipeline to transition to a green state.
