<h1 align="center">Lyrics-on-Panel-v3</h1>

<p align="center">
  <a href="https://drive.google.com/file/d/1wo_2CpBg5cgbhNJqyb9LIaSVA5LmSR2S/view?usp=drive_link" target="_blank">
  	Watch DEMO Video
  </a>
</p>

<p align="center">
  <img src="img/image-panel-onlythiswidget.png" alt="Plasma Lyric Panel Demo" width="500"/>
</p>
<p align="center"><b><code>Display lyrics of the currently playing music anywhere on the screen</code></b></p>

----

### 🌟 v3.0.0 (Improved Version) - 2026

This is the enhanced version (v3) designed and developed in collaboration with Antigravity AI. It introduces advanced animations, performance optimizations, and user-experience improvements over the original version (v2):

#### 🚀 New Features & Improvements

1. **Apple Music Style Transitions (Slide-Up & Cross-Fade)**:
   - Implements smooth Apple Music style vertical transitions. The preview line slides up to replace the active line, scaling from `0.8` to `1.0` with fade transitions, while the old active line fades out and drifts upwards (`-4px`).
   - Unified rendering using hardware scaling (`scale: 0.8`) prevents font anti-aliasing redraws and flickering when changing sizes.
   - Synchronized font weights (bold/italic) eliminate visual jumps during lyric updates.

2. **Adaptive Font Sizing for Small Panels**:
   - Automatically detects the physical panel height. If the height is restricted and next line preview is enabled, it dynamically reduces the font size so that both lines fit perfectly without clipping.
   - Reverts back to the configured default size when the preview is disabled.

3. **Jitter-free Centering & Smooth Shift (`Behavior on y`)**:
   - The active line remains strictly centered vertically so its position is completely stable. Shifting is handled smoothly using a `200ms` `Behavior on y` easing animation.
   - The top coordinate is clamped (`Math.max(2, centerY)`) to ensure the text is never clipped at the top.

4. **Disk Cache Optimization (`/tmp` Cache)**:
   - Implements a SHA-256 local JSON cache under `/tmp/lyrics-on-panel-cache/` in the Python backend. It avoids duplicate network requests, consumes zero persistent storage, and automatically cleans up on system reboot.

5. **Manual Sync Offset**:
   - Adds a configuration slider/input to adjust a manual synchronization offset (from `-5000ms` to `+5000ms`) to correct laggy or fast lyrics.

6. **Full Backwards Compatibility**:
   - The backend server computes and outputs extra metadata while maintaining full backwards compatibility for v2 frontend applets.

----

### Features

This plugin replicates the top-bar lyrics display feature of NetEase Cloud Music/QQ Music on macOS.

👉 Original effect reference: [CSDN Blog Link](https://blog.csdn.net/weixin_34061200/article/details/112693092)

----

### How it works

* Retrieve information of currently playing music and music-player from the MPRIS2 data source. It is compatible with any player that correctly implements the **[MPRIS2 specification](https://specifications.freedesktop.org/mpris-spec/latest/)**.
  * Currently tested with:
    * Spotify
    * LX Music
    * SPlayer
    * Youtube Music
    * Netease Cloud Music (Not wine version)
    * Apple Music

* This plugin uses four approaches to fetch lyrics:
  1. **YesPlayMusic Mode** (https://github.com/qier222/YesPlayMusic): Fetches lyrics of the currently playing music from the local port exposed by YesPlayMusic.
  2. **LX Music Mode** ([lx-music-desktop](https://github.com/lyswhut/lx-music-desktop)): Fetches lyrics of the currently playing music from the local port exposed by LX Music.
  3. **SPlayer Mode** ([SPlayer](https://github.com/imsyy/SPlayer)): Fetches lyrics of the currently playing music from the local port exposed by SPlayer. (Only builds from version 2026.1.4 onwards are available: [3eda65d](https://github.com/imsyy/SPlayer/commit/3eda65dd89fdebade373f20b5890add6ac3ab3df))
  4. **Global Mode**: Fetches lyrics from the [LrcLib](https://lrclib.net/) lyrics database by precisely matching the `artist`, `music(track) title`, and `album name`. If no result is found, it falls back to a fuzzy search using only the **song title**.

----

### Installation Guide

#### KDE

We provide three frontend versions for KDE Plasma:
- **v1**: Pure QML implementation (legacy mode).
- **v2**: QML frontend with Python backend.
- **v3 (Recommended)**: QML frontend with Python backend, supporting vertical transitions, next line previews, adaptive font sizing, and caching.

There are two approaches to install the widget:

1. **GUI Method**: Install the frontend using the graphical interface provided by KDE (see [this link](https://userbase.kde.org/Plasma/Installing_Plasmoids)).
2. **CLI Method**: Install via command line:
   ```bash
   yay -S plasma-sdk
   git clone https://github.com/bogeta329/lyrics-on-panel-v3.git
   cd lyrics-on-panel-v3/kde/v3 # or cd to v2 / v1 if preferred
   kpackagetool6 -t Plasma/Applet -i .
   ```

* ⚠️⚠️⚠️ **v2 and v3 require the Python backend to work.** Install it with the following commands:
  ```bash
  cd lyrics-on-panel-v3
  chmod +x scripts/install-backend.sh
  ./scripts/install-backend.sh
  ```

----

### Showcase

#### KDE Plasma 6 (With [**Panel Colorizer**](https://github.com/luisbocanegra/plasma-panel-colorizer))

![Plasma6 Showcase](img/image-20240529024104188.png)

#### KDE Plasma 5

![Plasma5 Showcase](img/image-20240317192855544.png)

#### Panel Only

![Panel Showcase 1](img/image-20240529023754367.png)  
![Panel Showcase 2](img/image-20240529023819659.png)

#### Synchronized Lyrics

![image-20250525014042601](img/README/image-20250525014042601.png)

#### Configuration Page

<p align="center">
  <img src="img/README/image-20250525013647423.png" alt="Customizing Components">
</p>

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=bogeta329/lyrics-on-panel-v3&type=date&legend=top-left)](https://www.star-history.com/#bogeta329/lyrics-on-panel-v3&type=date&legend=top-left)
