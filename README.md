<p align="center">
  <img src="mj.png" alt="hee-hee" width="200">
</p>

<h1 align="center">hee-hee</h1>

<p align="center">A macOS menu bar app that makes Michael Jackson dance across the bottom of your screen at random intervals, complete with "hee-hee!" and "hoooo!" sound effects and speech bubbles.</p>

<p align="center">
  <a href="https://github.com/notuselessdev/hee-hee/releases/latest"><img src="https://img.shields.io/github/v/release/notuselessdev/hee-hee" alt="Release"></a>
  <a href="https://github.com/notuselessdev/hee-hee/blob/main/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="License"></a>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-blue" alt="Platform">
</p>

> **Fan-made project.** It is not affiliated with, endorsed by, or associated with the Michael Jackson estate or any related entities. All trademarks belong to their respective owners.

## Install

### Homebrew

```sh
brew install notuselessdev/tap/hee-hee
```

### Manual

Download the latest `.dmg` from [Releases](https://github.com/notuselessdev/hee-hee/releases) and drag hee-hee to your Applications folder.

### macOS Gatekeeper

hee-hee is not notarized by Apple, so macOS will block it the first time you open it. To allow it:

1. Open hee-hee -- macOS will show a warning and prevent it from opening
2. Go to **System Settings > Privacy & Security**
3. Scroll down to the Security section -- you'll see a message about hee-hee being blocked
4. Click **Open Anyway**
5. Confirm in the dialog that appears

You only need to do this once.

## Features

- Lives in the menu bar -- no dock icon
- MJ dances across the bottom of your screen at random intervals (1-60 min, configurable)
- Alternates direction each walk with sprite flipping
- Green-screen video with real-time chroma key compositing
- "hee-hee!" and "hoooo!" sound effects at random points during each walk
- Comic-style speech bubbles that follow the character
- Manual trigger via menu bar or `Cmd+Shift+M`
- Launch at login support
- Preferences for timer interval, sound, and speech bubble toggles
- Respects system mute and volume

## Requirements

- macOS 13 (Ventura) or later

## Building from Source

```sh
git clone https://github.com/notuselessdev/hee-hee.git
cd hee-hee
open HeeHee.xcodeproj
```

Build and run from Xcode (`Cmd+R`).

## Disclaimer

This is an unofficial fan-made project created for entertainment purposes only. The Michael Jackson video footage used in this app is sourced from publicly available green-screen material and is not owned by the developer. If you are a rights holder and have concerns, please open an issue.

## License

[MIT](LICENSE)
