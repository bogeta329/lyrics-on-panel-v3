<h1 align="center">Lyrics-on-Panel-v3-sbs</h1>

<p align="center">
  <a href="https://drive.google.com/file/d/1wo_2CpBg5cgbhNJqyb9LIaSVA5LmSR2S/view?usp=drive_link" target="_blank">
  	点击查看DEMO视频 (Watch demo video)
  </a>
</p>

<p align="center">
  <img src="img/image-panel-onlythiswidget.png" alt="Plasma Lyric Panel Demo" width="500"/>
</p>
<p align="center"><b><code>在屏幕的任何地方显示正在播放音乐的歌词  
</code></b></p>
<p align="center"><b><code>Display lyrics of the currently playing music anywhere on the screen</code></b></p>

----

### 🌟 v3.0.0 (SBS Improved Version) - 2026

这个版本是由 Antigravity AI 与 user pairing 共同设计开发的增强版 (v3)，在原版 (v2) 的基础上引入了多项高级动画、性能优化和易用性改进：

> This is the enhanced version (v3) designed and developed in collaboration with Antigravity AI and pairing partner. It introduces advanced animations, performance optimizations, and user-experience improvements over the original version (v2):

#### 🚀 新功能与改进 (New Features & Improvements)

1. **歌词淡入淡出及滑动效果 (Apple Music Style Transitions)**:
   - 实现了类似于 Apple Music 的纵向滑动效果。当下一行歌词准备好时，下方的预览行会向上滑入，伴随着尺寸从 `0.8` 缩放到 `1.0`，透明度从设定的预览值提升到 100%，而当前的歌词行则渐隐并稍微向上偏移（`-4px`）。
   - *This version implements smooth Apple Music style vertical transitions. The preview line slides up to replace the active line, scaling from `0.8` to `1.0` with fade transitions, while the old active line fades out.*

2. **歌词大小智能自适应 (Adaptive Font Sizing for Small Panels)**:
   - 自动检测 KDE 面板的物理高度。若面板高度较小且开启了歌词预览，会智能等比缩小字体，确保双行歌词完全可见而不被裁剪。如果关闭预览，字体会自动变大。
   - *Automatically detects the physical panel height. If the height is restricted and next line preview is enabled, it dynamically reduces the font size so that both lines fit perfectly without clipping.*

3. **稳定无跳动垂直居中 (Jitter-free Centering & Behavior on y)**:
   - 只有主歌词始终保持垂直居中，即使下一行预览歌词由于数据变动出现或消失，当前正在播放的歌词位置也完全不动，杜绝抖动。高度变化时伴随 200ms 的平滑垂直插值滑动 (`Behavior on y`)。
   - *Only the active line remains strictly centered so its vertical position is completely stable. Shifting is handled smoothly using a 200ms `Behavior on y` animation. The top line is clamped (`Math.max(2, centerY)`) so it is never cut off.*

4. **磁盘缓存加速 (`/tmp` Cache)**:
   - 在后台 Python 进程中实现了基于 SHA-256 哈希的本地 `/tmp` 缓存。下载过的歌曲歌词会自动缓存，避免重复请求并减轻 CPU 负担，在电脑关机/重启时由系统自动清理。
   - *Implements a SHA-256 local JSON cache under `/tmp/lyrics-on-panel-cache/`. It avoids duplicate network requests, consumes zero persistent storage, and automatically cleans up on system reboot.*

5. **手动歌词同步偏移 (Manual Sync Offset)**:
   - 增加手动在配置面板微调延迟的功能（支持 `-5000ms` 至 `+5000ms`），解决某些歌词与音频不同步的问题。
   - *Adds a configuration slider/input to adjust a manual synchronization offset (from `-5000ms` to `+5000ms`) to correct laggy or fast lyrics.*

6. **全向后兼容 (Backwards Compatible)**:
   - Python 后台以无损的向后兼容格式输出了 `next_lyric`, `current_lyric_duration_ms` 和 `time_remaining_ms`，因此无论运行 v2 还是 v3 版本的前端 widget 都能共用同一个后台！
   - *The backend server computes and outputs extra metadata while maintaining full backwards compatibility for v2 frontend applets.*

----

### 功能介绍  (Features)

本插件**完美还原**了MacOS 下「网易云音乐/QQ音乐」的歌词顶栏显示功能。  

> This plugin perfectly replicates the top-bar lyrics display feature of NetEase Cloud Music on macOS.  

👉 原始效果参考：[CSDN 博文链接](https://blog.csdn.net/weixin_34061200/article/details/112693092)  

> 👉 For the original effect reference, see: [CSDN Blog Link](https://blog.csdn.net/weixin_34061200/article/details/112693092)   

----

### 工作原理  (How it works)

* 从Mpris2数据源中获取当前播放歌曲以及播放器的信息。全局模式适用于所有正确实现了**[MPRIS2 规范](https://specifications.freedesktop.org/mpris-spec/latest/)** 的播放器。

  > Retrieve information of currently playing music and music-player from the MPRIS2 data source. The Global Mode mentioned below is compatible and should work with any players that correctly implement the **[MPRIS2 specification](https://specifications.freedesktop.org/mpris-spec/latest/)**.

  * 目前已知支持(Currently tested with)：
    * Spotify
    * LX Music
    * SPlayer
    * Youtube Music
    * Netease Cloud Music (Not wine version)
    * Apple Music
    * SPlayer

* 根据歌曲信息，采用三套逻辑进行歌词抓取：  

  > This plugin uses three approaches to fetch lyrics:

  1. YesPlayMusic模式 (YesPlayMusic Mode)  https://github.com/qier222/YesPlayMusic  
     从 YesPlayMusic 暴露在本地的端口获取当前播放歌曲的歌词。  

     > Fetches lyrics of the currently playing music from the local port exposed by YesPlayMusic. 

  2. LX Music 模式 (LX Music Mode)  **[lx-music-desktop](https://github.com/lyswhut/lx-music-desktop)**
       从 LX Music 暴露在本地的端口获取当前播放歌曲的歌词

     > Fetches lyrics of the currently playing music from the local port exposed by LX Music.

  3. SPlayer 模式 (SPlayer Mode)  **[SPlayer](https://github.com/imsyy/SPlayer)**
       从 SPlayer 暴露在本地的端口获取当前播放歌曲的歌词
       仅2026.1.4以后构建的版本可用[3eda65d](https://github.com/imsyy/SPlayer/commit/3eda65dd89fdebade373f20b5890add6ac3ab3df)

     > Fetches lyrics of the currently playing music from the local port exposed by SPlayer.
     > Only builds from version 2026.1.4 onwards are available.[3eda65d](https://github.com/imsyy/SPlayer/commit/3eda65dd89fdebade373f20b5890add6ac3ab3df)

  4. 全局模式 (Global Mode)
     从 [**LrcLib**](https://lrclib.net/) 歌词数据库中根据 **`歌手`、`曲名`、`专辑名`** 精确匹配歌词。若无匹配结果，则使用 **歌名** 模糊查询。  
  
     > Fetches lyrics from the [Lrclib](https://lrclib.net/) lyrics database by precisely matching the `artist`, `music(track) title`, and `album name`. If no result is found, then fallback to a fuzzy search using only the **song title**. 

----

### 安装指南 (Installation Guide)

#### KDE

> 针对KDE Plasma， 我们提供两套版本，分别是纯QML实现以及前端QML后端Python。具体请见v1.4和v2.0的ChangeLog。

>> For KDE Plasma, we provide two versions: a pure QML implementation and a QML frontend with Python backend. Please refer to the ChangeLog for v1.4 and v2.0 for details.

当前仓库版本仅保证在 **KDE Plasma 6** 下工作。 如需要 **KDE Plasma5** 版本，请在 [**KDE Store**](https://store.kde.org/p/2138263) 或 [**Plasma5 分支**](https://github.com/KangweiZhu/lyrics-on-panel/tree/plasma5) 进行下载。

> The current repository version only supports **KDE Plasma 6**. If you need the **KDE Plasma5** version, please download it from the [**KDE Store**](https://store.kde.org/p/2138263) or the [**Plasma5 branch**](https://github.com/KangweiZhu/lyrics-on-panel/tree/plasma5).  

Plasma5版本是**可用但过时**的版本，许多在新版本加入的功能， 以及Bug修复都尚未应用在Plasma5版本。

> Plasma5 version is **usable but outdated**. Many features and bug fixes introduced in the new version are not applied to the Plasma5 version.



有**两种安装方式**可选：  

> As for **installing the widget,** you will have 2 approaches:  

1. 无论是v1（**纯QML实现， 传统模式**）还是v2（**更灵活与精确的模式**）, 都推荐使用 KDE 官方提供的图形界面方式安装**前端**，详见[此链接](https://userbase.kde.org/Plasma/Installing_Plasmoids)。  ****

   > Regardless of whether you are using v1 (**pure QML implementation, legacy mode**) or v2 (**a more flexible and precise mode**), it is recommended to install the **frontend** using the GUI method provided by the KDE official website  (see [this link](https://userbase.kde.org/Plasma/Installing_Plasmoids)). 
   
   


2. 也可以通过命令行完成**v1/v2**前端的安装

   > you can use the following commands to test and install:

   ```bash
   yay -S plasma-sdk
   git clone git@github.com:KangweiZhu/lyrics-on-panel.git
   cd lyrics-on-panel/kde/v2 # or cd lyrics-on-panel/kde/v1 if you want v1
   kpackagetool6 -t Plasma/Applet -i .
   ```



* ⚠️⚠️⚠️**v2需要额外的Python后端才能够工作。在 Arch Linux 下, 后端可以通过以下命令完成安装。**⚠️⚠️⚠️

  > Note that v2 (**a more flexible and precise mode**) requires an additional Python backend to make the frontend work. **Rest assured, the backend can be installed on Arch Linux with the following commands.**

  ```
  git clone git@github.com:KangweiZhu/lyrics-on-panel.git
  cd lyrics-on-panel
  chmod +x scripts/install-backend.sh
  ./scripts/install-backend.sh
  ```



#### DMS




----

### 展示（Showcase）  

#### KDE Plasma6（配合 [**Panel Coloizer**](https://github.com/luisbocanegra/plasma-panel-colorizer)）
> Under KDE Plasma 6 (With [**Panel Coloizer**](https://github.com/luisbocanegra/plasma-panel-colorizer)).

![Plasma6 展示](img/image-20240529024104188.png)

  

  



---

  

  



#### KDE Plasma 5

> Under KDE Plasma 5  

![Plasma5 展示](img/image-20240317192855544.png "Fullscreen shortcut")  

  



---

  

  



#### 仅在面板中显示（Panel Only）  

> Display only on Panel Only  
>
> 

![Panel 展示1](img/image-20240529023754367.png)  
![Panel 展示2](img/image-20240529023819659.png)

  

  



---

  

  



#### 同步歌词显示（Synchronized Lyrics）  

> Synchronized lyrics  

![image-20250525014042601](img/README/image-20250525014042601.png)  

  



---

  

  



#### 配置页面  (Configuration Page)

> Freedom of customizing every component of this widget  

<p align="center">
  <img src="img/README/image-20250525013647423.png" alt="Customizing Components">
</p>

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=KangweiZhu/lyrics-on-panel&type=date&legend=top-left)](https://www.star-history.com/#KangweiZhu/lyrics-on-panel&type=date&legend=top-left)
