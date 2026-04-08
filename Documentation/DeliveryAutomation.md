# Delivery Automation

This repository now keeps the release delivery procedure in repo-owned files so
the shipping surface stays explicit even when a single checkout produces
multiple deliverables.

## Monorepo-style procedure

Treat each release surface as a matrix row instead of scattering scheme
selection across shell snippets or ad hoc CI edits.

- The source of truth for iOS delivery targets lives in
  [`automation/delivery_matrix.json`](../automation/delivery_matrix.json).
- The manual dispatcher lives in
  [`.github/workflows/fastlane-delivery.yml`](../.github/workflows/fastlane-delivery.yml).
- The reusable Fastlane lanes live in [`fastlane/`](../fastlane/).

Keeping the matrix in one file makes it easier to add or retire targets such as
`iOS`, `iOS-SE`, and `iOS-Remote` without changing the workflow shape every
time.

## Delivery matrix

| Target | Track | Fastlane lane | Scheme | Bundle identifier source |
| --- | --- | --- | --- | --- |
| `ios-testflight` | `testflight` | `deploy_testflight` | `iOS` | `IOS_APP_IDENTIFIER` |
| `ios-se-testflight` | `testflight` | `deploy_testflight` | `iOS-SE` | `IOS_SE_APP_IDENTIFIER` |
| `ios-remote-testflight` | `testflight` | `deploy_testflight` | `iOS-Remote` | `IOS_REMOTE_APP_IDENTIFIER` |
| `ios-se-appstore` | `appstore` | `deploy_appstore` | `iOS-SE` | `IOS_SE_APP_IDENTIFIER` |
| `ios-remote-appstore` | `appstore` | `deploy_appstore` | `iOS-Remote` | `IOS_REMOTE_APP_IDENTIFIER` |

The workflow supports `testflight`, `appstore`, or `all` and can run in
`dry_run` mode to verify the matrix and command lines without uploading
artifacts.

## MacBook runner pool

The current reference builder is the MacBook-hosted runner that was validated on
2026-04-08 with this state:

- Host: `MacBook-Pro.local`
- macOS: `15.5`
- Xcode: `16.1`
- Fastlane: `2.232.2`
- GitHub CLI: `2.89.0`
- Runner name: `macbook-pro-utm`
- Runner labels: `self-hosted,macOS,ARM64,realagi-mac,apple-builder,utm`
- Runner root: `/Volumes/ActionsRunner/runners/utm`

Use [`automation/bootstrap_actions_runner.sh`](../automation/bootstrap_actions_runner.sh)
to install, reconfigure, or inspect the runner from the MacBook over SSH.

## Workflow inputs

The dispatcher accepts:

- `ref`: branch, tag, or SHA to release from
- `track`: `testflight`, `appstore`, or `all`
- `dry_run`: print the Fastlane commands instead of executing them
- `skip_codesign`: pass `skip_codesign:true` into Fastlane

The workflow resolves runner labels from `SELF_HOSTED_RUNNER_LABELS_JSON` when
present, otherwise it falls back to the current MacBook pool labels.

## Required variables and secrets

These names line up with the existing release process and are mapped into
Fastlane's environment:

- Variables: `APPLE_ID`, `APP_STORE_CONNECT_TEAM_ID`, `CONNECT_KEY_ID`,
  `CONNECT_ISSUER_ID`, `DEVELOPER_PORTAL_TEAM_ID` or `SIGNING_TEAM_ID`,
  `IOS_APP_IDENTIFIER`, `IOS_SE_APP_IDENTIFIER`, `IOS_REMOTE_APP_IDENTIFIER`,
  `DELIVERY_DEVELOPER_DIR`, `SELF_HOSTED_RUNNER_LABELS_JSON`
- Secrets: `CONNECT_KEY`, `MATCH_PASSWORD`, `MATCH_GIT_BASIC_AUTHORIZATION`

The workflow does not require all variables for every matrix row. For example,
`IOS_REMOTE_APP_IDENTIFIER` is only needed when the matching row is selected.

## Debugging checklist

Run these on the MacBook when a self-hosted delivery job is unhealthy:

```sh
automation/bootstrap_actions_runner.sh status
gh api repos/realagiorganization/UTM/actions/runners
tail -n 50 /Volumes/ActionsRunner/runners/utm/_diag/*.log
launchctl print "gui/$(id -u)/dev.realagi.actions.runner.utm"
ps -ax | grep Runner.Listener
```

For CI-level debugging, dispatch the workflow with `dry_run=true` first. That
verifies matrix expansion, ref selection, runner routing, and the exact Fastlane
command lines before the build host touches signing or App Store Connect.
