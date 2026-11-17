# Good Morning

An alarm you can only silence by actually waking up: get out of bed, do verified exercise in
front of the camera, finish the routine. iPhone + Apple Watch, personal TestFlight build.

- Design and decisions: [docs/architecture.md](docs/architecture.md)
- Core logic (runs anywhere Swift does): `Packages/GoodMorningCore`
- iPhone app: `App/GoodMorning`, Watch app: `App/GoodMorningWatch`

## UI lab

`docs/ui-lab/index.html` shows every screen in the browser with live colour pickers for the
theme tokens. Serve the repo root and open it (the sound buttons play the real alarm files):

```bash
python -m http.server 8765
```

Then open http://localhost:8765/docs/ui-lab/ . Token names match `App/GoodMorning/UI/Theme.swift`.

Alarm sounds are generated, not recorded: `python tools/make_sounds.py`.

## Develop

Core logic, on any OS:

```bash
swift test --package-path Packages/GoodMorningCore
```

The app itself needs macOS to build. CI does it on GitHub Actions (`.github/workflows/ci.yml`):
XcodeGen turns `project.yml` into an Xcode project, then `xcodebuild` compiles it.
