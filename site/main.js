// 主题偏好归网站所有；首帧主题已由文档头部内联脚本写入根元素，这里负责后续切换、持久化与系统偏好跟随。
const themeButton = document.querySelector('.theme-toggle');
const themeMeta = document.querySelector('meta[name="theme-color"]');
const systemTheme = window.matchMedia('(prefers-color-scheme: light)');
let savedTheme;
try { savedTheme = localStorage.getItem('mochi-site-theme'); } catch (_) { /* 使用系统主题。 */ }
if (savedTheme !== 'light' && savedTheme !== 'dark') savedTheme = null;
function currentTheme() {
  const applied = document.documentElement.dataset.theme;
  if (applied === 'light' || applied === 'dark') return applied;
  return systemTheme.matches ? 'light' : 'dark';
}
function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  if (themeMeta) themeMeta.content = theme === 'dark' ? '#101014' : '#faf9fc';
  if (!themeButton) return;
  const nextLabel = theme === 'dark' ? '切换到浅色模式' : '切换到深色模式';
  themeButton.setAttribute('aria-label', nextLabel);
  themeButton.title = nextLabel;
  const icon = themeButton.querySelector('.theme-icon');
  if (icon) icon.textContent = theme === 'dark' ? '☼' : '☾';
}
applyTheme(currentTheme());
if (themeButton) {
  themeButton.hidden = false;
  themeButton.addEventListener('click', () => {
    savedTheme = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
    applyTheme(savedTheme);
    try { localStorage.setItem('mochi-site-theme', savedTheme); } catch (_) { /* 不影响本次切换。 */ }
  });
}
// 早期 Safari 只有 addListener；缺失时仅失去跟随系统主题的能力，不影响其余交互。
const followSystemTheme = (event) => {
  if (!savedTheme) applyTheme(event.matches ? 'light' : 'dark');
};
if (systemTheme.addEventListener) systemTheme.addEventListener('change', followSystemTheme);
else if (systemTheme.addListener) systemTheme.addListener(followSystemTheme);
// 截图交互归网站页面所有；加载失败时保留当前截图，所有预览素材复用仓库文档。
const gallery = document.querySelector('[data-gallery]');
const image = document.querySelector('#gallery-image');
const caption = document.querySelector('#gallery-caption');
const tabList = gallery ? gallery.querySelector('.gallery-tabs') : null;
const previews = {
  movies: ['电影库的海报墙界面', '让文件夹里的片名，变成一眼就想点开的海报墙。'],
  detail: ['影片详情，包含简介、评分与演职员信息', '故事、评分与演职员信息，在开始观看之前多了解一点。'],
  playback: ['独立播放器的播放界面', '选好音轨与字幕，把时间留给电影。'],
  'file-browser': ['媒体源文件浏览界面', '从熟悉的目录出发，浏览已连接媒体源中的文件。'],
  settings: ['应用设置界面', '主题、语言与媒体源，把 Mochi 调整成你喜欢的样子。'],
};
let requestId = 0;
if (gallery && image && caption && tabList) {
  tabList.hidden = false;
  gallery.addEventListener('click', (event) => {
    const button = event.target.closest('button[data-image]');
    if (!button) return;
    const selected = button.dataset.image;
    if (!previews[selected]) return;
    const currentRequest = ++requestId;
    const next = new Image();
    next.onload = () => {
      if (currentRequest !== requestId) return;
      image.width = next.naturalWidth;
      image.height = next.naturalHeight;
      image.src = next.src;
      image.alt = previews[selected][0];
      caption.textContent = previews[selected][1];
      tabList.querySelectorAll('button').forEach((item) => {
        item.setAttribute('aria-pressed', String(item === button));
      });
    };
    next.onerror = () => {
      if (currentRequest === requestId) caption.textContent = '截图加载失败，请稍后重新选择。';
    };
    next.src = button.dataset.src;
  });
}
