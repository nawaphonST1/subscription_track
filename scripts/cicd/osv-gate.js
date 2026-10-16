#!/usr/bin/env node
// ==============================================================================
// osv-gate.js - Severity gate for osv-scanner JSON reports (Jenkinsfile.mobile)
// ==============================================================================
// Usage: node scripts/cicd/osv-gate.js <osv-scanner-report.json>
//
// Mirrors the backend DP-402 pnpm audit gate: the scanner is run with `|| true`
// (osv-scanner exits non-zero on ANY finding), then this script decides:
//   - critical + high > 0           -> exit 1 ("BLOCKING: N critical, N high ...")
//   - medium / low / unknown        -> reported, never blocking
//   - missing / empty / invalid JSON -> exit 1 (a gate must not pass on a broken report)
//   - {"results":[]} (stub)         -> zero findings, exit 0
//
// Counting: one finding per osv-scanner "group" (deduplicated vulnerability, i.e.
// GHSA/CVE aliases collapse into one). Vulnerabilities not referenced by any group
// (or all of them, for packages without "groups") count individually.
// Severity: numeric groups[].max_severity (CVSS: >=9 critical, >=7 high, >=4 medium,
// >0 low) first, then database_specific.severity (CRITICAL/HIGH/MODERATE|MEDIUM/LOW).
// Anything else is "unknown" (printed as a warning, does not block).
// ==============================================================================
"use strict";
const fs = require("fs");

const SEV_RANK = { critical: 4, high: 3, medium: 2, low: 1, unknown: 0 };

function fromScore(value) {
    const n = typeof value === "number" ? value : parseFloat(value);
    if (!Number.isFinite(n) || n <= 0) return null;
    if (n >= 9.0) return "critical";
    if (n >= 7.0) return "high";
    if (n >= 4.0) return "medium";
    return "low";
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

// Highest label-based severity among the given vulnerability objects.
function labelSeverity(vulns) {
    let sev = "unknown";
    for (const v of vulns) {
        const s = fromLabel(v && v.database_specific && v.database_specific.severity);
        if (s) sev = worst(sev, s);
    }
    return sev;
}

// Severity of a single vulnerability object: label first, then any numeric CVSS score in severity[].
function ungroupedSeverity(v) {
    const byLabel = fromLabel(v.database_specific && v.database_specific.severity);
    if (byLabel) return byLabel;
    let sev = "unknown";
    for (const entry of Array.isArray(v.severity) ? v.severity : []) {
        const s = fromScore(entry && entry.score);
        if (s) sev = worst(sev, s);
    }
    return sev;
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
                const sev = fromScore(g && g.max_severity) || labelSeverity(members);
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
        `[osv-scanner] Summary: Critical: ${c.critical}, High: ${c.high}, Medium: ${c.medium}, Low: ${c.low}, Unknown: ${c.unknown}`
    );
    if (c.unknown > 0) {
        console.warn(`[osv-scanner] WARNING: ${c.unknown} finding(s) have no usable severity (not blocking) - review the report manually.`);
    }
    if (c.critical > 0 || c.high > 0) {
        console.error(`[osv-scanner] BLOCKING: ${c.critical} critical, ${c.high} high severity finding(s).`);
        process.exit(1);
    }
}

if (require.main === module) {
    main();
}
module.exports = { classifyReport };
