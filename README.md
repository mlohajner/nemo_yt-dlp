# Nemo Copy-Paste Actions for yt-dlp

Three small shell scripts and nemo_actions for downloading video/audio
from: YouTube, Facebook and any site supported by `yt-dlp`.  
Three modes:  
- a Nemo file manager action (right-click menu) or
- custom keyboard shortcut (clipboard URL)
- CLI command video.sh <destination> <URL>

## Usage

It's just a copy-paste action. Copy a video URL, then "paste" it into a
folder using the Nemo action. Everything else (reading the clipboard,
validating the URL, parsing timestamps, running `yt-dlp`, handling
errors, opening the result) happens automatically behind the scene.

1. Copy a video URL (YouTube, Facebook, or any supported site) to your clipboard.
2. In Nemo, right-click inside the folder where you want the file, and pick
   the action (e.g. "Paste Video", "Paste MP3", "Paste Music").
3. Wait for the download to finish. Nemo refreshes to show the new file, or a
   notification pops up if something went wrong.

In keyboard-shortcut mode it's the same behavior, except it
always saves into a fixed default folder instead of asking you to pick one:

```
/tmp/nemo_yt-dlp
```

Copy a link - press the shortcut - done.

## Features

- Supports **X11** (`xclip`) and **Wayland** (`wl-clipboard`) clipboard reading
- Basic dependency checks (`yt-dlp`, clipboard tool) with desktop notifications on failure
- Desktop notifications (`notify-send`) if `yt-dlp` fails to download
- Custom timestamp support via URL query parameters, independent of the site itself:
  - `t` — start time
  - `e` — end time
  - `d` — duration (takes priority over `e` when both are given)
- Timestamp formats accepted for `t`, `e`, and `d`:
  - Plain seconds: `t=90`
  - Seconds with suffix: `t=90s`
  - Minutes and seconds: `t=1m30s`
  - Hours, minutes, and seconds: `t=1h5m10s`
- Works with any site `yt-dlp` supports (YouTube, Facebook, Instagram, Twitter/X,
  TikTok, Vimeo, Twitch, Reddit, SoundCloud, and more...)
- Three separate scripts, one per output format, so each is easy to customize on its own:
  - `video.sh` — video, up to 1080p, muxed to MP4
  - `audio.sh` — best available audio, kept as-is (typically `.webm`)
  - `mp3.sh` — best available audio, transcoded to MP3
- A shared `common.sh` handles everything the three scripts have in common
  (dependency checks, clipboard reading, URL validation, timestamp parsing)

## Installation

Inluded is `install.sh`, edit to check and verify the information provided.

- INSTALL_DIR - is the location where scripts live
- ACTIONS_DIR - is the nemo actions location

When ready:
```bash
chmod +x install.sh
./install.sh
```

## Requirements

- `yt-dlp`
- `ffmpeg` (needed by `yt-dlp` for merging video+audio and for MP3 transcoding —
  not checked up front; if missing, the affected download will simply fail with
  a notification instead of transcoding correctly)
- One of:
  - `xclip` (X11)
  - `wl-clipboard` (Wayland, provides `wl-paste`)
- `notify-send` (usually part of `libnotify`) for error notifications
- `nemo` = Nemo file manager, used to open the destination folder once the
  download finishes (--self patch recommended to reuse already opened nemo instance)

## Timestamp Parameters

Append these as extra query parameters on the URL (in the clipboard or the
argument) to download only part of a video:

| Parameter | Meaning        | Example        |
|-----------|----------------|----------------|
| `t`       | Start time     | `t=1m30s`      |
| `e`       | End time       | `e=2m10s`      |
| `d`       | Duration       | `d=30s`        |

Examples:

```
...&t=33&e=80        -> download from 33s to 80s
...&t=1m&d=20s        -> download 20s starting at 1 minute
...&t=1h5m10s          -> download starting at 1h05m10s to the end
```

Notes:

- `d` takes priority over `e` if both are present.
- These parameters are interpreted by the script itself — `youtube.com`'s own
  `t=` parameter (e.g. from "Copy video URL at current time") uses the same
  format, so links copied straight from YouTube work as-is. `e` and `d` are
  script-only additions and are ignored by the site itself.
- If a value doesn't match any of the supported formats, it's ignored and the
  full video is downloaded instead.

## Error Handling

If `yt-dlp` is missing, no clipboard tool is available, the clipboard is
empty, or the download itself fails, a desktop notification is shown via
`notify-send` explaining what went wrong. Non-URL clipboard contents are
silently ignored (the script just exits) so it's safe to bind to a shortcut
you might press by accident.

## Customization

- Change the default folder for keyboard-shortcut mode by editing the
  `TARGET_DIR="${1:-/tmp/nemo_yt-dlp}"` line in each script (for each format).
- Change video quality, audio format, or add extra `yt-dlp` flags directly in
  the `yt-dlp` call at the bottom of the relevant script (`video.sh`,
  `audio.sh`, or `mp3.sh`) - each is independent of the other two.
