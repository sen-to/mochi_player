<p align="center">
  <img src="assets/branding/mochi_app_icon.svg" width="112" alt="Mochi Player 图标">
</p>

<h1 align="center">Mochi Player</h1>

<p align="center">
  让你的私人影片库，拥有接近流媒体服务的浏览与播放体验。
</p>

<p align="center">
  <a href="https://github.com/FENGYU-008/mochi_player/actions/workflows/windows.yml">
    <img src="https://github.com/FENGYU-008/mochi_player/actions/workflows/windows.yml/badge.svg" alt="Windows CI">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/license-GPL--3.0--only-7A6AB3" alt="GPL-3.0-only 许可证">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%20%7C%20Windows-5B6B8C" alt="支持 macOS 和 Windows">
</p>

Mochi Player 是一款面向 Windows 与 macOS 的本地优先媒体库播放器。连接本地目录或WebDAV 后，它会扫描并整理视频，使用 TMDB 补全海报、简介、评分、演职员和剧集信息，再以首页、海报墙与详情页重新呈现你的收藏。

从挑选影片到继续观看，一切都围绕舒服地看完一部作品：直接播放本地与 WebDAV 媒体、记忆播放进度，并支持多版本文件、音轨与字幕选择。Mochi 先专注把个人媒体库的核心体验做好，再逐步加入更具个性的功能。

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

- 🎞️ 浏览本地目录、WebDAV 和 OpenList 媒体库
- 🧹 扫描媒体文件；已有路径不会重复入库，已有元数据不会重复刮削
- 🎬 使用 TMDB 匹配电影、剧集、演职员、海报与背景图
- 🔎 浏览电影、剧集、收藏和继续观看内容
- ▶️ 播放本地文件与 WebDAV 直链
- ⏱️ 记忆播放进度，支持多版本媒体、字幕与播放偏好设置
- 🎨 支持浅色、深色、跟随系统主题与强调色选择

## 🖥️ 支持平台

| 平台 | 状态 |
| --- | --- |
| macOS | 已验证 |
| Windows | 已验证 |

## 🚀 开始使用

首次使用时，请依次完成以下配置：

1. 在“设置 → 元数据”中填写自己的 TMDB API Key。
2. 如网络环境需要，可开启 TMDB 代理并填写 HTTP 代理地址。
3. 在“设置 → 媒体源”中添加本地目录或 WebDAV 媒体源。
4. 扫描媒体源并开始浏览、播放。

后续扫描会重新枚举目录以识别删除项，但只将新增路径写入媒体库；已存在的元数据不会重复请求 TMDB。

TMDB Key 由用户自行申请和管理，请不要将自己的 Key 提交到仓库或截图中。

## 🛠️ 从源码运行

本项目通过 FVM 固定使用 Flutter 3.47.2（见 [`.fvmrc`](.fvmrc)）。构建 macOS 版本还需要 Xcode。

首次运行前安装 FVM 并下载项目指定的 Flutter SDK：

```bash
dart pub global activate fvm
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

macOS 当前使用 CocoaPods 管理原生插件。首次在 macOS 构建前执行 `fvm flutter config --no-enable-swift-package-manager`，避免启用实验性的 Swift Package Manager；部分上游插件尚未支持 SPM，Flutter 仍可能显示兼容性提示，但不影响当前 CocoaPods 构建。

提交代码前请执行：

```bash
fvm dart format lib test
fvm flutter analyze
fvm flutter test
```

## 🔒 数据与隐私

- 媒体库、播放进度和应用设置仅保存在本机。
- 媒体源账号和密码只用于连接用户配置的 WebDAV 服务。
- 当前版本的媒体源凭据存储在本机应用数据库中，尚未接入系统钥匙串；请不要在不受信任的共享设备上保存高权限账号。
- 启用 TMDB 后，影片名称等用于匹配的信息会发送至用户配置的 TMDB API 地址；海报与背景图会从 TMDB 图片服务下载并缓存。

## 📌 已知限制

- 应用界面当前仅提供简体中文，更多语言将陆续加入。
- TMDB 匹配依赖文件命名质量，少数作品可能需要后续手动处理。

## 🤝 参与贡献

欢迎通过 Issue 反馈问题、提出功能建议，或提交 Pull Request。提交前请确保格式化、静态检查和测试均通过。

## 🙏 致谢

本产品使用 [TMDB](https://www.themoviedb.org/) API，但未获得 TMDB 的认可或认证。

## 📄 许可证

本项目代码采用 [GNU GPL v3.0](LICENSE) 许可证发布。

`Mochi Player` 名称与 Logo 不随代码许可证授权；Fork 或衍生发行版请使用不同的名称和
视觉标识。详见 [品牌使用政策](TRADEMARKS.md)。
