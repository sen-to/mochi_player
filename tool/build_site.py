"""组装项目网站到 build/site；复用品牌与截图源文件，不依赖 Flutter 或第三方包。"""

from pathlib import Path
import shutil


root = Path(__file__).resolve().parent.parent
output = root / "build" / "site"
# 仅清理网站构建目录，避免旧文件进入部署包。
if output.exists():
    shutil.rmtree(output)
shutil.copytree(root / "site", output)
assets = output / "assets"
assets.mkdir()
shutil.copy2(root / "assets/branding/mochi_app_icon.svg", assets)
shutil.copytree(root / "docs/images/screenshots", assets / "screenshots",
                ignore=shutil.ignore_patterns(".*"))
(output / ".nojekyll").touch()
print(f"网站已生成：{output}")
