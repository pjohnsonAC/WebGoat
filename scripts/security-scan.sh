#!/usr/bin/env bash
set -u

mkdir -p reports

run() {
  echo "::group::$1"
  shift
  "$@" || true
  echo "::endgroup::"
}

run "Trivy JSON" trivy fs --scanners vuln,secret,misconfig --format json -o reports/trivy.json .
run "Trivy SARIF" trivy fs --scanners vuln,secret,misconfig --format sarif -o reports/trivy.sarif .
run "Semgrep SARIF" semgrep scan --config p/default --config p/secrets --sarif --output reports/semgrep.sarif .
run "Gitleaks JSON" gitleaks detect --source . --no-git --redact --report-format json --report-path reports/gitleaks.json

if [ "${RUN_DEPENDENCY_CHECK:-false}" = "true" ] && [ -x ./mvnw ]; then
  run "OWASP Dependency-Check JSON" ./mvnw -q org.owasp:dependency-check-maven:check -Dformat=JSON -DfailBuildOnCVSS=11
  if [ -f target/dependency-check-report.json ]; then
    cp target/dependency-check-report.json reports/dependency-check-report.json
  fi
fi
