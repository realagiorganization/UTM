## Assumptions Made During Automated Execution

- Apple Developer credentials and App Store Connect API keys are **not** available in this environment and must be provided via GitHub encrypted secrets.
- TestFlight deployment is expected to use App Store Connect API (JWT) rather than interactive `altool` login.
- The repository does not currently contain any GitHub Actions workflows for iOS CI/CD.
- A minimal, non-leaking workflow is acceptable as a first verifiable step, with secure secrets wiring left to repository settings.
- UI testing GIF and screenshots will be added later once CI runners and simulators are finalized.

