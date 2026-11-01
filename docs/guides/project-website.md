# 项目网站

项目网站是独立于 Flutter 应用的静态展示页，源码入口为 [`site/index.html`](../../site/index.html)，样式与截图交互在同目录。内容以根 README 的用户功能与限制为依据；发布状态变化时同步下载区。网站不包含播放器运行环境或用户数据。

主 slogan 统一为“你的收藏，你的影院。”，网站与 README 使用“连接本地与网络存储，让整理、挑选和观看影片更舒服”解释产品能力。数据保存在本机与联网访问媒体源 / TMDB 的边界放在隐私说明中。

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

线上地址：[https://sen-to.github.io/mochi_player/](https://sen-to.github.io/mochi_player/)。仓库已启用 GitHub Actions 发布，2026-11-01 [首次部署成功](https://github.com/sen-to/mochi_player/actions/runs/41262628836)，对应提交 `a05d2fc`。后续网站变更推送到 `master` 后自动发布。

[`pages.yml`](../../.github/workflows/pages.yml) 在相关文件的 PR 中组装网站；合入 `master` 或手动运行后部署。网站与应用的双平台构建相互独立，不改动现有应用检查。

首次启用：

1. 将网站源码和工作流提交到 GitHub。
2. 仓库 **Settings → Pages → Build and deployment → Source** 选择 **GitHub Actions**。
3. 在 **Actions → Project website** 手动运行工作流，或推送网站变更到 `master`。
4. 以 `github-pages` 环境返回的部署地址为准。默认项目地址预计为 `https://sen-to.github.io/mochi_player/`；配置文件存在不代表已经启用或部署成功。

工作流只授予部署任务 `pages: write` 与 `id-token: write`，PR 不执行部署。配置依据 [GitHub 官方自定义工作流文档](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)（2026-11-01 核对）。

## 搜索引擎

页面标题包含产品名称、支持平台与产品类型，description 描述实际能力；canonical 与 `og:url` 均指向 `https://sen-to.github.io/mochi_player/`。[`site/sitemap.xml`](../../site/sitemap.xml) 只列出首页，组装时复制到 `build/site/sitemap.xml`，不将页内锚点列成独立页面。更换网站域名时同步这三个绝对网址。

2026-11-01，已在 Google Search Console 添加网址前缀资源 `https://sen-to.github.io/mochi_player/`，通过 HTML 标记完成所有权验证。首页的 `google-site-verification` 元标记需要长期保留，更换模板时不可移除。首页请求编入索引已被接受并加入优先抓取队列，目前尚未收录。

`https://sen-to.github.io/mochi_player/sitemap.xml` 已提交，但 Search Console 首次处理与复查仍显示“无法抓取”。本机检查其 HTTP 响应为 200、XML 有效且首页地址正确；域名根目录的 `robots.txt` 返回 404。上述检查不能代表 Google 的抓取结果，后续在“站点地图”页面复查状态；若持续失败，再结合实际网址测试排查。不要将提交成功或加入抓取队列描述为已经收录，也无需反复请求同一首页。

规范网址与站点地图依据 Google 的[规范网址说明](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)与[站点地图说明](https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap)（2026-11-01 核对）。
