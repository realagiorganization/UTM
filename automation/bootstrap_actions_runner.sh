#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Bootstrap or inspect the GitHub Actions runner used by this repository.

Usage:
  automation/bootstrap_actions_runner.sh bootstrap
  automation/bootstrap_actions_runner.sh status
  automation/bootstrap_actions_runner.sh remove

Environment:
  GITHUB_REPOSITORY             GitHub repository path
                                default: realagiorganization/UTM
  RUNNER_ROOT                   Runner install root
                                default: /Volumes/ActionsRunner/runners/utm
  RUNNER_NAME                   Runner name shown in GitHub
                                default: macbook-pro-utm
  RUNNER_LABELS                 Comma-separated runner labels
                                default: self-hosted,macOS,ARM64,realagi-mac,apple-builder,utm
  RUNNER_PLIST_ID               LaunchAgent identifier
                                default: dev.realagi.actions.runner.utm
  RUNNER_VERSION                GitHub Actions runner version
                                default: 2.328.0
  RUNNER_ARCH                   Runner archive architecture
                                default: arm64
  FORCE_RECONFIGURE             Re-register the runner even if .runner exists
                                default: 0
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-realagiorganization/UTM}"
RUNNER_ROOT="${RUNNER_ROOT:-/Volumes/ActionsRunner/runners/utm}"
RUNNER_NAME="${RUNNER_NAME:-macbook-pro-utm}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,macOS,ARM64,realagi-mac,apple-builder,utm}"
RUNNER_PLIST_ID="${RUNNER_PLIST_ID:-dev.realagi.actions.runner.utm}"
RUNNER_VERSION="${RUNNER_VERSION:-2.328.0}"
RUNNER_ARCH="${RUNNER_ARCH:-arm64}"
FORCE_RECONFIGURE="${FORCE_RECONFIGURE:-0}"
LAUNCH_AGENT_PATH="${HOME}/Library/LaunchAgents/${RUNNER_PLIST_ID}.plist"
RUNNER_URL="https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-osx-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

runner_api_json() {
  gh api "repos/${GITHUB_REPOSITORY}/actions/runners"
}

fetch_registration_token() {
  gh api -X POST "repos/${GITHUB_REPOSITORY}/actions/runners/registration-token" --jq .token
}

fetch_remove_token() {
  gh api -X POST "repos/${GITHUB_REPOSITORY}/actions/runners/remove-token" --jq .token
}

ensure_runner_files() {
  mkdir -p "${RUNNER_ROOT}" "${RUNNER_ROOT}/_diag"
  if [[ ! -x "${RUNNER_ROOT}/config.sh" ]]; then
    curl -fsSL "${RUNNER_URL}" | tar -xz -C "${RUNNER_ROOT}"
  fi
}

write_launch_agent() {
  mkdir -p "$(dirname "${LAUNCH_AGENT_PATH}")"
  cat > "${LAUNCH_AGENT_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${RUNNER_PLIST_ID}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>-lc</string>
    <string>cd "${RUNNER_ROOT}" &amp;&amp; ./run.sh</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>WorkingDirectory</key>
  <string>${RUNNER_ROOT}</string>
  <key>StandardOutPath</key>
  <string>${RUNNER_ROOT}/_diag/launchd.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${RUNNER_ROOT}/_diag/launchd.stderr.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
EOF
}

load_launch_agent() {
  launchctl bootout "gui/$(id -u)" "${LAUNCH_AGENT_PATH}" >/dev/null 2>&1 || true
  launchctl bootstrap "gui/$(id -u)" "${LAUNCH_AGENT_PATH}"
  launchctl kickstart -k "gui/$(id -u)/${RUNNER_PLIST_ID}"
}

configure_runner() {
  local registration_token
  registration_token="$(fetch_registration_token)"

  if [[ -f "${RUNNER_ROOT}/.runner" && "${FORCE_RECONFIGURE}" == "1" ]]; then
    (cd "${RUNNER_ROOT}" && ./config.sh remove --token "$(fetch_remove_token)") || true
  fi

  if [[ ! -f "${RUNNER_ROOT}/.runner" || "${FORCE_RECONFIGURE}" == "1" ]]; then
    (
      cd "${RUNNER_ROOT}"
      ./config.sh \
        --unattended \
        --replace \
        --url "https://github.com/${GITHUB_REPOSITORY}" \
        --token "${registration_token}" \
        --name "${RUNNER_NAME}" \
        --labels "${RUNNER_LABELS}" \
        --work "_work"
    )
  fi
}

print_status() {
  echo "Repository: ${GITHUB_REPOSITORY}"
  echo "Runner root: ${RUNNER_ROOT}"
  echo "Runner name: ${RUNNER_NAME}"
  echo "Runner labels: ${RUNNER_LABELS}"
  echo "LaunchAgent: ${RUNNER_PLIST_ID}"
  echo

  if [[ -f "${RUNNER_ROOT}/.runner" ]]; then
    echo "Local runner metadata:"
    sed -n '1,120p' "${RUNNER_ROOT}/.runner"
    echo
  else
    echo "Local runner metadata: missing"
    echo
  fi

  echo "GitHub registration:"
  python3 - "${RUNNER_NAME}" <<'PY'
import json
import subprocess
import sys

name = sys.argv[1]
raw = subprocess.check_output(["gh", "api", "repos/realagiorganization/UTM/actions/runners"])
data = json.loads(raw)
for runner in data.get("runners", []):
    if runner.get("name") == name:
        print(json.dumps(runner, indent=2))
        break
else:
    print(f"runner {name!r} not found in GitHub API output")
PY
  echo

  echo "launchctl:"
  launchctl print "gui/$(id -u)/${RUNNER_PLIST_ID}" 2>/dev/null | sed -n '1,80p' || echo "not loaded"
  echo

  echo "Processes:"
  ps -ax -o pid=,command= | grep -E "Runner.Listener|actions.runner" | grep -v grep || true
  echo

  echo "Recent diagnostics:"
  ls -1t "${RUNNER_ROOT}/_diag" 2>/dev/null | head -n 5 | sed 's/^/  /' || true
}

remove_runner() {
  launchctl bootout "gui/$(id -u)" "${LAUNCH_AGENT_PATH}" >/dev/null 2>&1 || true
  if [[ -f "${RUNNER_ROOT}/.runner" ]]; then
    (cd "${RUNNER_ROOT}" && ./config.sh remove --token "$(fetch_remove_token)")
  fi
}

main() {
  local command="${1:-status}"
  case "${command}" in
    bootstrap)
      require_cmd gh
      require_cmd curl
      require_cmd tar
      require_cmd launchctl
      ensure_runner_files
      configure_runner
      write_launch_agent
      load_launch_agent
      print_status
      ;;
    status)
      require_cmd gh
      print_status
      ;;
    remove)
      require_cmd gh
      remove_runner
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      echo "unknown command: ${command}" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
