# Timer For Mac

A macOS timer app for people who work at a computer: track work sessions and breaks with a configurable daily plan.

## Status
- Step 1 done: timer core (engine + reducer), minimal UI, unit tests, zero warnings policy.

## MVP Goals
- Configurable workday plan (work/break/lunch segments)
- Auto-start/auto-stop by time
- Minimal timer mode (digits only)
- Compact status strip + full day timeline
- Runs reliably across app background/minimize; recovers after sleep/lock
- Optional display sleep prevention while timer is running

## Project Principles
- SwiftUI-first; AppKit bridge only where required (window management, sleep prevention, menubar/status)
- No business logic inside SwiftUI Views
- Testable core logic (schedule calculations, timer state machine)
- Zero Xcode warnings (treat warnings as errors)

## How to Run
1. Open `TimerForMac.xcodeproj`
2. Select target `TimerForMac` and run (⌘R)

## How to Test
- Run all tests: ⌘U

## Repository Workflow (solo)
- `dev` is the working branch
- `main` is stable/release-ready
- Merge `dev` -> `main` only when a milestone is complete
