// 截图交互归网站页面所有；加载失败时保留当前截图，所有预览素材复用仓库文档。
const gallery = document.querySelector('[data-gallery]');
const image = document.querySelector('#gallery-image');
const caption = document.querySelector('#gallery-caption');
const previews = {
  movies: ['电影库的海报墙界面', '让文件夹里的片名，变成一眼就想点开的海报墙。'],
  detail: ['影片详情，包含简介、评分与演职员信息', '故事、评分与演职员信息，在开始观看之前多了解一点。'],
  playback: ['独立播放器的播放界面', '选好音轨与字幕，把时间留给电影。'],
  'file-browser': ['媒体源文件浏览界面', '从熟悉的目录出发，浏览已连接媒体源中的文件。'],
  settings: ['应用设置界面', '主题、语言与媒体源，把 Mochi 调整成你喜欢的样子。'],
};
let requestId = 0;
gallery.querySelector('.gallery-tabs').hidden = false;
gallery.addEventListener('click', (event) => {
  const button = event.target.closest('button[data-image]');
  if (!button) return;
  const selected = button.dataset.image;
  const currentRequest = ++requestId;
  const next = new Image();
  next.onload = () => {
    if (currentRequest !== requestId) return;
    image.src = next.src;
    image.alt = previews[selected][0];
    caption.textContent = previews[selected][1];
    gallery.querySelectorAll('button').forEach((item) => {
      item.setAttribute('aria-pressed', String(item === button));
    });
  };
  next.onerror = () => {
    if (currentRequest === requestId) caption.textContent = '截图加载失败，请稍后重新选择。';
  };
  next.src = `./assets/screenshots/${selected}.webp`;
});
