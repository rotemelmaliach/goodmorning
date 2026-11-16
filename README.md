# Good Morning

An alarm you can only silence by actually waking up: get out of bed, do verified exercise in
front of the camera, finish the routine. iPhone + Apple Watch, personal TestFlight build.

- Design and decisions: [docs/architecture.md](docs/architecture.md)
- Core logic (runs anywhere Swift does): `Packages/GoodMorningCore`
- iPhone app: `App/GoodMorning`, Watch app: `App/GoodMorningWatch`

## Develop

Core logic, on any OS:

```bash
swift test --package-path Packages/GoodMorningCore
```

The app itself needs macOS to build. CI does it on GitHub Actions (`.github/workflows/ci.yml`):
XcodeGen turns `project.yml` into an Xcode project, then `xcodebuild` compiles it.
