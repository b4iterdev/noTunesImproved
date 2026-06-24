# noTunes Improved

A macOS menu bar app that blocks Apple Music (and iTunes) from auto-launching — especially when you connect headphones or AirPods. Unlike a blunt "kill on launch" approach, it combines audio-device monitoring with user-input activity to distinguish a system auto-launch from a manual launch.

## Features

- **Two blocking modes:**
  - **Always block** — terminates Music/iTunes every time it launches
  - **Headphone-triggered only** — blocks only when Music launches shortly after a headphone/Bluetooth device activation, *and* there's no recent user input (so manual launches still work)
- **Configurable block list** — toggle Music and iTunes independently
- **Replacement launcher** — open Spotify, YouTube Music, or any app/URL after blocking
- **Menu bar app** — no Dock icon, minimal resource usage

## Install

### Download the prebuilt binary

1. Go to [Releases](../../releases) and download `noTunesImproved-macOS.zip`
2. Unzip and move `noTunesImproved.app` to `/Applications`
3. **Bypass Gatekeeper** (the app is unsigned):
   - Right-click the app → **Open** → **Open** in the dialog
   - Or run: `xattr -cr /Applications/noTunesImproved.app`
4. Launch the app — a headphones icon appears in the menu bar

### Build from source

```bash
git clone https://github.com/b4iterdev/noTunesImproved.git
cd noTunesImproved
open noTunesImproved.xcodeproj
```

Build and run in Xcode (Cmd+R). Requires Xcode 16+ and macOS 12.4+.

## Usage

- Click the headphones icon in the menu bar to:
  - Toggle blocking on/off
  - Switch between **Always block** and **Headphone-triggered only** modes
  - Open the configuration window
  - Quit
- In **Configuration**, set a replacement app or URL (e.g. `https://music.youtube.com` or `/Applications/Spotify.app`)

## How headphone-triggered blocking works

1. When you connect headphones/AirPods, `AudioDeviceMonitor` detects the audio device change via CoreAudio
2. If Apple Music launches within 8 seconds of that activation, the app checks HID idle time
3. If the user was **active** (recent keyboard/mouse input) → **manual launch → allowed**
4. If the user was **idle** (no recent input) → **auto-launch → blocked**

macOS exposes no public API to determine the *cause* of an app launch, so this timing + input-activity heuristic is the most reliable approach that works without private APIs or special permissions.

## Releasing

Releases are built automatically via GitHub Actions. To publish a new release:

```bash
git tag v1.0.0
git push --tags
```

This triggers the [release workflow](.github/workflows/release.yml), which builds an unsigned `.app` and publishes it to GitHub Releases.

## License

MIT (pending)
