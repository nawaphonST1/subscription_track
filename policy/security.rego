package security

default allow := false

# Clause 1: Allow build if no deny rules are triggered
allow if {
    count(deny) == 0
}

# Clause 2: Deny build if dependency scan reports any CRITICAL CVE
deny contains msg if {
    input.metadata.vulnerabilities.critical > 0
    msg := sprintf("Dependency scan reported %v CRITICAL vulnerability (threshold: 0 allowed)", [input.metadata.vulnerabilities.critical])
}

deny contains msg if {
    some pkg_name, vuln in input.vulnerabilities
    vuln.severity == "critical"
    msg := sprintf("Package '%v' has CRITICAL severity vulnerability", [pkg_name])
}
