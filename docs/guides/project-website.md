# 项目网站

项目网站是独立于 Flutter 应用的静态展示页，源码入口为 [`site/index.html`](../../site/index.html)，样式与截图交互在同目录。内容以根 README 的用户功能与限制为依据；发布状态变化时同步下载区。网站不包含播放器运行环境或用户数据。

## 本地维护

只需要 Python 3；无需安装前端依赖或运行 Flutter：

```bash
python3 tool/build_site.py
python3 -m http.server 8765 --bind 127.0.0.1 --directory build/site
```

打开 `http://127.0.0.1:8765`。修改后重新执行组装并刷新页面。组装只重建已忽略的 `build/site`，从 `assets/branding/` 与 `docs/images/screenshots/` 复制素材，不维护第二套截图。所有站内资源使用相对路径，适配 GitHub Pages 的仓库子路径。

验证 JavaScript 语法、差异格式以及生成页面的资源链接：

```bash
node --check site/main.js
git diff --check
```

浏览器检查桌面与手机布局、截图按钮与键盘焦点、FAQ 展开、站内导航、双平台构建入口。纯网站改动无需执行 Flutter 回归。

## GitHub Pages

[`pages.yml`](../../.github/workflows/pages.yml) 在相关文件的 PR 中组装网站；合入 `master` 或手动运行后部署。网站与应用的双平台构建相互独立，不改动现有应用检查。

首次启用：

1. 将网站源码和工作流提交到 GitHub。
2. 仓库 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。
3. 在 **Actions → Project website** 手动运行工作流，或推送网站变更到 `master`。
4. 以 `github-pages` 环境返回的部署地址为准。默认项目地址预计为 `https://sen-to.github.io/mochi_player/`；配置文件存在不代表已经启用或部署成功。

工作流只授予部署任务 `pages: write` 与 `id-token: write`，PR 不执行部署。配置依据 [GitHub 官方自定义工作流文档](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)（2026-11-01 核对）。
