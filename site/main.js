// 主题偏好归网站所有；首帧主题已由文档头部内联脚本写入根元素，这里负责后续切换、持久化与系统偏好跟随。
const themeButton = document.querySelector('.theme-toggle');
const themeMeta = document.querySelector('meta[name="theme-color"]');
const systemTheme = window.matchMedia('(prefers-color-scheme: light)');
let savedTheme;
try {
    savedTheme = localStorage.getItem('mochi-site-theme');
} catch (_) { /* 使用系统主题。 */
}
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
        try {
            localStorage.setItem('mochi-site-theme', savedTheme);
        } catch (_) { /* 不影响本次切换。 */
        }
    });
}
// 早期 Safari 只有 addListener；缺失时仅失去跟随系统主题的能力，不影响其余交互。
const followSystemTheme = (event) => {
    if (!savedTheme) applyTheme(event.matches ? 'light' : 'dark');
};
if (systemTheme.addEventListener) systemTheme.addEventListener('change', followSystemTheme);
else if (systemTheme.addListener) systemTheme.addListener(followSystemTheme);
// 截图交互归网站页面所有；两张截图叠放做交叉淡入，加载失败时保留当前画面。
const gallery = document.querySelector('[data-gallery]');
const shots = gallery ? Array.from(gallery.querySelectorAll('.shot')) : [];
const caption = document.querySelector('#gallery-caption');
const tabList = gallery ? gallery.querySelector('.gallery-tabs') : null;
const indicator = tabList ? tabList.querySelector('.tab-indicator') : null;
const previews = {
    movies: ['电影库的海报墙界面', '让文件夹里的片名，变成一眼就想点开的海报墙。'],
    detail: ['影片详情，包含简介、评分与演职员信息', '故事、评分与演职员信息，在开始观看之前多了解一点。'],
    playback: ['独立播放器的播放界面', '选好音轨与字幕，把时间留给电影。'],
    'file-browser': ['媒体源文件浏览界面', '从熟悉的目录出发，浏览已连接媒体源中的文件。'],
    settings: ['应用设置界面', '主题、语言与媒体源，把 Mochi 调整成你喜欢的样子。'],
};
let requestId = 0;
let activeShot = shots[0] || null;

// 滑块按选中按钮的实际位置平移；窗口尺寸变化后重新对齐。
function moveIndicator(button) {
    if (!indicator || !button || !tabList) return;
    const style = getComputedStyle(tabList);
    const inset = parseFloat(style.borderLeftWidth) + parseFloat(style.paddingLeft);
    const box = tabList.getBoundingClientRect();
    const rect = button.getBoundingClientRect();
    indicator.style.width = rect.width + 'px';
    indicator.style.transform = 'translateX(' + (rect.left - box.left - inset) + 'px)';
}

if (gallery && activeShot && caption && tabList) {
    tabList.hidden = false;
    moveIndicator(tabList.querySelector('button[aria-pressed="true"]') || tabList.querySelector('button'));
    gallery.addEventListener('click', (event) => {
        const button = event.target.closest('button[data-image]');
        if (!button || !previews[button.dataset.image]) return;
        const incoming = activeShot === shots[0] ? shots[1] : shots[0];
        if (!incoming) return;
        const currentRequest = ++requestId;
        const preload = new Image();
        preload.onload = () => {
            if (currentRequest !== requestId) return;
            const [alt, text] = previews[button.dataset.image];
            incoming.src = preload.src;
            incoming.alt = alt;
            incoming.removeAttribute('aria-hidden');
            // 解码完成后再切换层级，避免淡入时出现空白帧；解码迟迟不返回时依然切换，不留死锁。
            let swapped = false;
            const apply = () => {
                if (swapped || currentRequest !== requestId) return;
                swapped = true;
                incoming.classList.add('is-active');
                activeShot.classList.remove('is-active');
                activeShot.alt = '';
                activeShot.setAttribute('aria-hidden', 'true');
                activeShot = incoming;
            };
            if (incoming.decode) {
                incoming.decode().then(apply, apply);
                setTimeout(apply, 120);
            } else {
                apply();
            }
            caption.textContent = text;
            tabList.querySelectorAll('button').forEach((item) => {
                item.setAttribute('aria-pressed', String(item === button));
            });
            moveIndicator(button);
        };
        preload.onerror = () => {
            if (currentRequest === requestId) caption.textContent = '截图加载失败，请稍后重新选择。';
        };
        preload.src = button.dataset.src;
    });
    window.addEventListener('resize', () => {
        moveIndicator(tabList.querySelector('button[aria-pressed="true"]'));
    });
}
// 滚动入场：进入视口后只播一次，来回滚动不重复闪烁。
const revealItems = document.querySelectorAll('[data-reveal], [data-reveal-group]');
if ('IntersectionObserver' in window) {
    const revealObserver = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (!entry.isIntersecting) return;
            entry.target.classList.add('in');
            revealObserver.unobserve(entry.target);
        });
    }, {rootMargin: '0px 0px -10% 0px', threshold: 0.12});
    revealItems.forEach((item) => revealObserver.observe(item));
} else {
    revealItems.forEach((item) => item.classList.add('in'));
}
const canHover = window.matchMedia('(hover: hover) and (pointer: fine)').matches;
const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
// 首屏截图视差：幅度控制在 1.2° 以内，指针离开立即回正。
const hero = document.querySelector('.hero');
const heroShot = document.querySelector('.hero-preview img');
if (canHover && hero && heroShot && !reduceMotion.matches) {
    hero.addEventListener('pointermove', (event) => {
        const rect = hero.getBoundingClientRect();
        const x = (event.clientX - rect.left) / rect.width - 0.5;
        const y = (event.clientY - rect.top) / rect.height - 0.5;
        heroShot.style.setProperty('--ry', (x * 1.6).toFixed(2) + 'deg');
        heroShot.style.setProperty('--rx', (-y * 1.2).toFixed(2) + 'deg');
    });
    hero.addEventListener('pointerleave', () => {
        heroShot.style.removeProperty('--rx');
        heroShot.style.removeProperty('--ry');
    });
}

