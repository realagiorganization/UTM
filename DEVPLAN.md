# Development Plan

## Goals

- Maintain a reliable iOS/macOS virtualization app built on QEMU.
- Keep the Swift/Objective-C frontends in sync with the virtualization backends.
- Provide repeatable build, test, and release workflows for contributors.

## Suggested Development Flow

1. Read the platform-specific guides: `Documentation/MacDevelopment.md` and `Documentation/iOSDevelopment.md`.
2. Set up the toolchain and dependencies listed below.
3. Build the macOS app target locally to validate the environment.
4. Build the iOS app target on a device or simulator that matches the supported OS range.
5. Update or add VM templates, UI flows, and configuration schemas as needed.
6. Validate changes using existing CI workflows and the BDD suite in `bdd/`.
7. Update documentation and changelog for any user-facing changes.

## External Dependencies

- Xcode + Apple SDKs (macOS/iOS) for building and signing the app.
- QEMU for system emulation backends bundled or built for the app targets.
- SPICE/QXL for graphics and input channels used by the VM frontend.
- Hypervisor.framework for macOS virtualization acceleration.
- Virtualization.framework for macOS 12+ guest virtualization support.
- SwiftPM/CocoaPods dependencies used by the frontend:
  - IQKeyboardManager
  - SwiftTerm
  - ZIPFoundation
  - InAppSettingsKit
- CI infrastructure dependencies:
  - GitHub Actions runners
  - MacStadium macOS hosts (for macOS/iOS builds)

## Local Validation Checklist

- Build and run the macOS app from `UTM.xcodeproj`.
- Build and install the iOS app on a device or simulator.
- Import or create a VM and verify basic run/pause/stop flows.
- Run the BDD suite via `behave` to keep documented use cases current.
