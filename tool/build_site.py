"""组装项目网站到 build/site；复用品牌与截图源文件，不依赖 Flutter 或第三方包。"""

from datetime import date
from pathlib import Path
import hashlib
import re
import shutil
from urllib.parse import urlsplit, urlunsplit


root = Path(__file__).resolve().parent.parent
output = root / "build" / "site"
site_url = "https://sen-to.github.io/mochi_player"
# 仅清理网站构建目录，避免旧文件进入部署包。
if output.exists():
    shutil.rmtree(output)
shutil.copytree(root / "site", output)
assets = output / "assets"
assets.mkdir()
shutil.copy2(root / "assets/branding/mochi_app_icon.svg", assets)
# 分享卡片按固定尺寸提供给各类爬虫与社交平台，不参与内容版本号，便于长期缓存。
shutil.copy2(root / "assets/branding/og-card.png", assets)
shutil.copytree(root / "docs/images/screenshots", assets / "screenshots",
                ignore=shutil.ignore_patterns(".*", "*.png"))
# 站点地图补 lastmod，让爬虫按构建日期判断内容新鲜度。
sitemap = output / "sitemap.xml"
sitemap.write_text(
    re.sub(r"</loc>", f"</loc>\n    <lastmod>{date.today().isoformat()}</lastmod>",
           sitemap.read_text(encoding="utf-8")),
    encoding="utf-8")


# 按内容生成资源版本；同名截图替换后避免浏览器继续复用旧缓存。
def version_asset(match):
    url = urlsplit(match.group(2))
    path = output / url.path
    if url.scheme or url.netloc or not url.path or not path.is_file():
        return match.group(0)
    if path.suffix not in {".css", ".js", ".webp", ".svg"}:
        return match.group(0)
    digest = hashlib.sha256(path.read_bytes()).hexdigest()[:12]
    versioned = urlunsplit(("", "", url.path, "v=" + digest, url.fragment))
    return match.group(1) + versioned + '"'


index = output / "index.html"
index.write_text(re.sub(r'(\b(?:src|href|data-src)=")([^"<>]+)"', version_asset,
                        index.read_text(encoding="utf-8")), encoding="utf-8")
# 抓取规则与站点地图声明；AI 检索器显式放行，避免站点被当作无关仓库内容。
robots = [
    "User-agent: *",
    "Allow: /",
    "",
    f"Sitemap: {site_url}/sitemap.xml",
    "",
]
for bot in ("GPTBot", "ClaudeBot", "PerplexityBot", "Google-Extended",
            "Applebot-Extended", "CCBot", "Bytespider"):
    robots += [f"User-agent: {bot}", "Allow: /", ""]
(output / "robots.txt").write_text("\n".join(robots), encoding="utf-8")
(output / ".nojekyll").touch()
print(f"网站已生成：{output}")
