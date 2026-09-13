<p align="center">
  <img src="assets/branding/mochi_app_icon.svg" width="112" alt="Mochi Player 图标">
</p>

<h1 align="center">Mochi Player</h1>

<p align="center">
  让你的私人影片库，拥有接近流媒体服务的浏览与播放体验。
</p>

<p align="center">
  <a href="https://github.com/sen-to/mochi_player/actions/workflows/windows.yml">
    <img src="https://github.com/sen-to/mochi_player/actions/workflows/windows.yml/badge.svg" alt="Windows CI">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-GPL--3.0--only-7A6AB3" alt="GPL-3.0-only 许可证">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Windows-5B6B8C" alt="支持 macOS 和 Windows">
</p>

Mochi Player 是一款面向 Windows 与 macOS 的本地优先媒体库播放器。连接本地目录、WebDAV 或 SMB 网络共享后，它会扫描并整理视频，使用 TMDB 补全海报、简介、评分、演员和剧集信息，再以首页、海报墙与详情页重新呈现你的收藏。

从挑选影片到继续观看，一切都围绕舒服地看完一部作品：直接播放本地、WebDAV 与 SMB 媒体，记忆播放进度，并支持多版本文件、音轨与字幕选择。Mochi 先专注把个人媒体库的核心体验做好，再逐步加入更具个性的功能。

## 🖼️ 界面预览

![首页](docs/images/home.png)

| 电影 | 媒体详情 |
| --- | --- |
| ![电影库](docs/images/movies.png) | ![媒体详情](docs/images/detail.png) |

| 文件浏览 | 播放 |
| --- | --- |
| ![文件浏览](docs/images/file-browser.png) | ![播放](docs/images/playback.png) |

![设置](docs/images/settings.png)

## ✨ 功能

**媒体库**

- 🎞️ 浏览本地目录、WebDAV 与 SMB 网络共享
- 🗂️ 通过 WebDAV 接入 OpenList / AList 等聚合网盘服务
- 🧹 扫描媒体文件；已有路径不会重复入库，已有元数据不会重复刮削
- 🎬 使用 TMDB 匹配电影、剧集、演员、海报与背景图
- 🔎 浏览电影、剧集、收藏和继续观看内容

**播放**

- ▶️ 播放本地文件，以及 WebDAV / SMB 直链
- 🪟 播放器可开在独立窗口；也可收成小窗（mini 播放器），并支持置顶
- ⏱️ 记忆播放进度，支持多版本文件、音轨与内嵌 / 外挂字幕
- 🔠 可用 Mochi 字幕样式覆盖字幕文件自带的字体与颜色
- ⚡ 播放速度 0.5×–2×、实时缓存速度显示、拖动进度条时的时间预览

**外观**

- 🎨 支持浅色、深色、跟随系统主题与强调色选择

## 🖥️ 支持平台

| 平台 | 状态 |
| --- | --- |
| macOS | 已验证。暂无 CI，需要从源码构建 |
| Windows | 已验证。有 CI 构建，见下方「下载与安装」 |

## 📥 下载与安装

构建产物通过 GitHub Actions 提供：

1. 打开 [Windows CI](https://github.com/sen-to/mochi_player/actions/workflows/windows.yml)，选择最近一次成功的运行；
2. 在页面底部的 **Artifacts** 区域下载 `mochi-player-windows-x64`；
3. 解压后直接运行其中的 `mochi_player.exe`。

> Artifact 仅保留 14 天，过期后需要重新触发构建。macOS 版本目前需要从源码构建。

## 🚀 开始使用

首次使用时，请依次完成以下配置：

1. 在“设置 → 元数据”中填写自己的 TMDB API Key。
2. 如网络环境需要，可开启 TMDB 代理并填写 HTTP 代理地址。
3. 在“设置 → 媒体源”中添加媒体源，支持三种类型：
   - **本地目录**：本机磁盘或已挂载的目录；
   - **WebDAV**：标准 WebDAV 服务，也包括 OpenList / AList 这类以 WebDAV 暴露的聚合网盘（默认端口 5244，路径形如 `/dav/quark`）；
   - **SMB**：局域网内的 SMB / Samba 共享。
4. 扫描媒体源并开始浏览、播放。

后续扫描会重新枚举目录以识别删除项，但只将新增路径写入媒体库；已存在的元数据不会重复请求 TMDB。

TMDB Key 由用户自行申请和管理，请不要将自己的 Key 提交到仓库或截图中。

## ⌨️ 快捷键

主窗口：

| 快捷键 | 作用 |
| --- | --- |
| `Cmd/Ctrl + K` | 聚焦搜索框 |
| `Esc` | 取消搜索框焦点（搜索框聚焦时） |

播放器：

| 快捷键 | 作用 |
| --- | --- |
| `Space` / `K` | 播放 / 暂停 |
| `←` / `J` | 后退 10 秒 |
| `→` / `L` | 前进 10 秒 |
| `↑` / `↓` | 音量 +5 / −5 |
| `M` | 静音切换 |
| `F` | 全屏切换 |
| `Esc` | 退出全屏 |
| `C` | 切换字幕轨 |
| `A` | 切换音轨 |

## 🛠️ 从源码运行

本项目通过 FVM 固定使用 Flutter 3.47.2（见 [`.fvmrc`](.fvmrc)）。

构建前置条件：

- **macOS**：Xcode；最低部署目标为 macOS 12.0（见 `macos/Podfile`）。
- **Windows**：Visual Studio（2019 及以上，推荐 2022），安装时需勾选「使用 C++ 的桌面开发」工作负载。

首次运行前安装 FVM，并下载项目指定的 Flutter SDK。

macOS 推荐用 Homebrew：

```bash
brew install fvm
```

Windows 或其他平台，可以在已有 Dart / Flutter SDK 的前提下用 pub 安装：

```bash
dart pub global activate fvm
```

其他安装方式见 [FVM 官方文档](https://fvm.app/documentation/getting-started/installation)。用 `dart pub global activate` 安装时，`fvm` 可执行文件位于 `~/.pub-cache/bin`（Windows 为 `%LOCALAPPDATA%\Pub\Cache\bin`），需要把它加入 `PATH`。

然后安装 [`.fvmrc`](.fvmrc) 中锁定的 Flutter 版本：

```bash
fvm install
```

随后统一通过 `fvm flutter` 执行 Flutter 命令：

```bash
fvm flutter pub get
fvm flutter run -d macos
```

运行 Windows 版本：

```bash
fvm flutter run -d windows
```

构建 macOS Debug 应用：

```bash
fvm flutter build macos --debug
```

macOS 使用 CocoaPods 管理原生插件（`macos/Podfile`）。Flutter 3.47 默认开启 Swift Package Manager，而本项目尚未迁移到 SPM，因此在 macOS 上首次构建前建议先关闭它：

```bash
fvm flutter config --no-enable-swift-package-manager
```

提交代码前请执行：

```bash
fvm dart format lib test
fvm flutter analyze
fvm flutter test
```

代码统一使用 120 列，已在 [`analysis_options.yaml`](analysis_options.yaml) 的 `formatter.page_width` 中声明，因此 `fvm dart format` 无需额外参数。

修改 `lib/core/infrastructure/database/entities/` 下的实体后，需要重新生成 Isar 代码：

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

生成结果（`*.g.dart`）已随仓库提交，普通构建不需要执行这一步。

## 🗂️ 项目结构

```
lib/
├── app/        应用外壳：侧边栏、页面骨架与路由
├── core/       跨功能的领域模型、基础设施（数据库 / 存储源 / 播放解析）与设计系统
├── features/   按功能划分：home、library、playback、settings
└── main.dart   应用入口，同时负责区分媒体库主窗口与播放器窗口
test/           与 lib/ 结构对应的单元测试与 Widget 测试
windows/ macos/ 各平台 runner
```

> Windows 上主窗口引擎显式使用 `RunOnSeparateThread`（见 `windows/runner/flutter_window.cpp`）。
> 这不是可选项：默认策略会把 UI isolate 合并到 Win32 消息循环线程，导致窗口在特定交互下冻结。

## 🔒 数据与隐私

- 媒体库、播放进度和应用设置仅保存在本机。
- 媒体源账号和密码只用于连接用户配置的 WebDAV 或 SMB 服务。
- 当前版本的媒体源凭据存储在本机应用数据库中，尚未接入系统钥匙串；请不要在不受信任的共享设备上保存高权限账号。
- 启用 TMDB 后，影片名称等用于匹配的信息会发送至用户配置的 TMDB API 地址；海报与背景图会从 TMDB 图片服务下载并缓存。

## 📌 已知限制

- 应用界面当前仅提供简体中文，更多语言将陆续加入。
- TMDB 匹配依赖文件命名质量，少数作品可能需要后续手动处理。
- 关闭媒体库主窗口后，播放器窗口会继续播放，应用进程保持运行，直到播放器窗口也关闭。
- Windows 上打开播放器窗口后，媒体库主窗口可能出现鼠标与键盘无响应（界面渲染仍在继续），关闭播放器窗口也不会恢复。该问题已定位到当前多窗口实现所依赖的「同进程多 Flutter 引擎」，属于 Windows 平台层缺陷，正在评估替代方案。

## 🤝 参与贡献

欢迎通过 Issue 反馈问题、提出功能建议，或提交 Pull Request。提交前请确保格式化、静态检查和测试均通过。

## 🙏 致谢

本产品使用 [TMDB](https://www.themoviedb.org/) API，但未获得 TMDB 的认可或认证。

## 📄 许可证

本项目代码采用 [GNU GPL v3.0](LICENSE) 许可证发布。

`Mochi Player` 名称与 Logo 不随代码许可证授权；Fork 或衍生发行版请使用不同的名称和
视觉标识。详见 [品牌使用政策](TRADEMARKS.md)。
