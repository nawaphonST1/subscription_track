#!/usr/bin/env node
// ==============================================================================
// osv-gate.js - Severity gate for osv-scanner JSON reports (Jenkinsfile.mobile)
// ==============================================================================
// Usage: node scripts/cicd/osv-gate.js <osv-scanner-report.json>
//
// Mirrors the backend DP-402 pnpm audit gate: the scanner is run with `|| true`
// (osv-scanner exits non-zero on ANY finding), then this script decides:
//   - critical + high > 0           -> exit 1 ("BLOCKING: N critical, N high, N unclassifiable ...")
//   - unclassifiable severity > 0   -> exit 1 (fail-closed: a finding whose severity cannot be
//                                      determined blocks until it is triaged)
//   - medium / low                  -> reported, never blocking
//   - missing / empty / invalid JSON -> exit 1 (a gate must not pass on a broken report)
//   - {"results":[],...} (no findings) -> zero findings, exit 0
//
// Counting: one finding per osv-scanner "group" (deduplicated vulnerability, i.e.
// GHSA/CVE aliases collapse into one). Vulnerabilities not referenced by any group
// (or all of them, for packages without "groups") count individually.
//
// Severity precedence (the first that yields a result wins):
//   (a) numeric groups[].max_severity (>=9 critical, >=7 high, >=4 medium, >0 low)
//   (b) database_specific.severity label (CRITICAL/HIGH/MODERATE|MEDIUM/LOW)
//   (c) severity[] entries: a plain numeric score, or a CVSS v3.0 / v3.1 vector whose base
//       score is computed here (FIRST.org CVSS v3.1 spec formula); worst entry wins.
// CVSS v4.0 and v2 vectors are NOT scored (no approximation is attempted). An entry that is
// only a v4/v2 vector (or malformed / incomplete v3) is unclassifiable, i.e. FAIL-CLOSED:
// it counts as "unclassifiable" and blocks. Same for findings with no severity info at all.
// ==============================================================================
"use strict";
const fs = require("fs");

const SEV_RANK = { critical: 4, high: 3, medium: 2, low: 1, unknown: 0 };

function fromScore(value) {
    const n = typeof value === "number" ? value : typeof value === "string" && value.trim() !== "" ? Number(value) : NaN;
    if (!Number.isFinite(n) || n <= 0) return null;
    if (n >= 9.0) return "critical";
    if (n >= 7.0) return "high";
    if (n >= 4.0) return "medium";
    return "low";
}

// --- CVSS v3.0 / v3.1 base score (FIRST.org CVSS v3.1 specification, section 7) -----------
const V3_WEIGHTS = {
    AV: { N: 0.85, A: 0.62, L: 0.55, P: 0.2 },
    AC: { L: 0.77, H: 0.44 },
    UI: { N: 0.85, R: 0.62 },
    C: { H: 0.56, L: 0.22, N: 0 },
    I: { H: 0.56, L: 0.22, N: 0 },
    A: { H: 0.56, L: 0.22, N: 0 },
};
const V3_PR = { U: { N: 0.85, L: 0.62, H: 0.27 }, C: { N: 0.85, L: 0.68, H: 0.5 } };

// CVSS v3.1 Roundup (integer-based, avoids floating point artefacts).
function roundup(x) {
    const intInput = Math.round(x * 100000);
    if (intInput % 10000 === 0) return intInput / 100000;
    return (Math.floor(intInput / 10000) + 1) / 10.0;
}

// Returns the v3.x base score (0.0-10.0) or null if the vector is not a complete, valid v3.0/v3.1 vector.
function cvss3BaseScore(vector) {
    if (typeof vector !== "string") return null;
    const parts = vector.trim().split("/");
    if (parts[0] !== "CVSS:3.0" && parts[0] !== "CVSS:3.1") return null;
    const m = {};
    for (const part of parts.slice(1)) {
        const kv = part.split(":");
        if (kv.length !== 2 || Object.prototype.hasOwnProperty.call(m, kv[0])) return null;
        m[kv[0]] = kv[1];
    }
    const pick = (table, key) =>
        Object.prototype.hasOwnProperty.call(table, m[key]) ? table[m[key]] : undefined;
    if (m.S !== "U" && m.S !== "C") return null;
    const av = pick(V3_WEIGHTS.AV, "AV");
    const ac = pick(V3_WEIGHTS.AC, "AC");
    const pr = pick(V3_PR[m.S], "PR");
    const ui = pick(V3_WEIGHTS.UI, "UI");
    const c = pick(V3_WEIGHTS.C, "C");
    const i = pick(V3_WEIGHTS.I, "I");
    const a = pick(V3_WEIGHTS.A, "A");
    if ([av, ac, pr, ui, c, i, a].some((x) => x === undefined)) return null;
    const iss = 1 - (1 - c) * (1 - i) * (1 - a);
    const impact = m.S === "U" ? 6.42 * iss : 7.52 * (iss - 0.029) - 3.25 * Math.pow(iss - 0.02, 15);
    const expl = 8.22 * av * ac * pr * ui;
    if (impact <= 0) return 0;
    return m.S === "U"
        ? roundup(Math.min(impact + expl, 10))
        : roundup(Math.min(1.08 * (impact + expl), 10));
}

function fromLabel(value) {
    switch (String(value || "").trim().toUpperCase()) {
        case "CRITICAL": return "critical";
        case "HIGH": return "high";
        case "MODERATE":
        case "MEDIUM": return "medium";
        case "LOW": return "low";
        default: return null;
    }
}

function worst(a, b) {
    return SEV_RANK[a] >= SEV_RANK[b] ? a : b;
}

// Highest label-based severity among the given vulnerability objects (null if none).
function labelSeverity(vulns) {
    let sev = null;
    for (const v of vulns) {
        const s = fromLabel(v && v.database_specific && v.database_specific.severity);
        if (s) sev = sev ? worst(sev, s) : s;
    }
    return sev;
}

// Worst severity from severity[] entries: numeric score or computed CVSS v3.x vector.
// v4.0 / v2 vectors and malformed entries yield null (not scored; see header).
function scoreSeverity(vulns) {
    let sev = null;
    for (const v of vulns) {
        for (const entry of Array.isArray(v && v.severity) ? v.severity : []) {
            const raw = entry && entry.score;
            const computed = cvss3BaseScore(raw);
            // A valid vector scoring 0.0 ("None") is reported as low rather than unclassifiable.
            const s = fromScore(raw) || (computed === 0 ? "low" : fromScore(computed));
            if (s) sev = sev ? worst(sev, s) : s;
        }
    }
    return sev;
}

// Severity of a single vulnerability object: label first, then severity[] scores/vectors.
function ungroupedSeverity(v) {
    return fromLabel(v.database_specific && v.database_specific.severity) || scoreSeverity([v]) || "unknown";
}

function classifyReport(data) {
    const counts = { critical: 0, high: 0, medium: 0, low: 0, unknown: 0 };
    const results = Array.isArray(data && data.results) ? data.results : [];
    for (const res of results) {
        const packages = Array.isArray(res && res.packages) ? res.packages : [];
        for (const pkg of packages) {
            const vulns = Array.isArray(pkg && pkg.vulnerabilities) ? pkg.vulnerabilities : [];
            const groups = Array.isArray(pkg && pkg.groups) ? pkg.groups : [];
            const covered = new Set();
            for (const g of groups) {
                const ids = new Set([].concat((g && g.ids) || [], (g && g.aliases) || []));
                const members = vulns.filter(
                    (v) => v && (ids.has(v.id) || (v.aliases || []).some((a) => ids.has(a)))
                );
                members.forEach((v) => covered.add(v));
                const sev = fromScore(g && g.max_severity) || labelSeverity(members) || scoreSeverity(members) || "unknown";
                counts[sev]++;
            }
            // Vulnerabilities not referenced by any group (or all of them when there are no groups)
            // are never dropped: each counts individually via CVSS score / database_specific label.
            for (const v of vulns) {
                if (!v || covered.has(v)) continue;
                counts[ungroupedSeverity(v)]++;
            }
        }
    }
    return counts;
}

function main() {
    const reportPath = process.argv[2];
    if (!reportPath) {
        console.error("[osv-scanner] BLOCKING: no report path given.");
        process.exit(1);
    }
    let data;
    try {
        if (!fs.existsSync(reportPath) || fs.statSync(reportPath).size === 0) {
            throw new Error("report file is missing or empty");
        }
        data = JSON.parse(fs.readFileSync(reportPath, "utf8"));
    } catch (e) {
        console.error(`[osv-scanner] BLOCKING: cannot read report ${reportPath}: ${e.message}`);
        process.exit(1);
    }
    const c = classifyReport(data);
    console.log(
        `[osv-scanner] Summary: Critical: ${c.critical}, High: ${c.high}, Medium: ${c.medium}, Low: ${c.low}, Unclassifiable: ${c.unknown}`
    );
    if (c.critical > 0 || c.high > 0 || c.unknown > 0) {
        console.error(
            `[osv-scanner] BLOCKING: ${c.critical} critical, ${c.high} high, ${c.unknown} unclassifiable severity finding(s).`
        );
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}
module.exports = { classifyReport, cvss3BaseScore };
