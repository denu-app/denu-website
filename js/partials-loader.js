// Immediate theme initialization to prevent flash of incorrect theme
(function() {
  const savedTheme = localStorage.getItem('theme');
  const html = document.documentElement;
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
  
  // Function to apply theme
  function applyTheme(theme) {
    if (theme === 'system') {
      html.removeAttribute('data-theme');
      if (prefersDark.matches) {
        html.setAttribute('data-theme', 'dark');
      } else {
        html.setAttribute('data-theme', 'light');
      }
    } else {
      html.setAttribute('data-theme', theme);
    }
  }
  
  // Apply initial theme
  if (savedTheme) {
    applyTheme(savedTheme);
  } else {
    applyTheme('system');
  }
  
  // Listen for system theme changes (only if no explicit theme is stored)
  prefersDark.addEventListener('change', (e) => {
    if (!localStorage.getItem('theme')) {
      applyTheme('system');
    }
  });
})();

function loadPartial(id, url, callback) {
  fetch(url)
    .then(res => res.text())
    .then(html => {
      document.getElementById(id).innerHTML = html;
      if (callback) callback();
    })
    .catch(err => console.warn('Failed to load partial', url, err));
}

function loadScript(src, onload) {
  var s = document.createElement('script');
  s.src = src;
  s.onload = onload;
  document.body.appendChild(s);
}

// Track when both navbar and drawer are loaded
let navLoaded = false, drawerLoaded = false;
function tryInitMobileNav() {
  if (navLoaded && drawerLoaded) {
    loadScript('/js/mobile-nav.js', function() {
      if (window.initMobileNav) window.initMobileNav();
    });
  }
}

// Function to trigger language translation for loaded partials
function translateLoadedPartials() {
  if (window.languageManager) {
    window.languageManager.translatePage();
  } else {
    // If language manager is not ready yet, wait a bit and try again
    setTimeout(() => {
      if (window.languageManager) {
        window.languageManager.translatePage();
      }
    }, 100);
  }
}

// Load navbar, drawer, and footer
loadPartial('navbar', '/partials/navbar.html', function() {
  navLoaded = true;
  tryInitMobileNav();
  // Translate the loaded navbar content
  translateLoadedPartials();
  // After navbar is loaded, load theme-toggle.js if needed
  loadScript('/js/theme-toggle.js', function() {
    if (window.initThemeToggle) window.initThemeToggle();
  });
});
// Check if drawer element exists before loading
const drawerElement = document.getElementById('drawer');
if (drawerElement) {
  loadPartial('drawer', '/partials/drawer.html', function() {
    drawerLoaded = true;
    tryInitMobileNav();
    // Translate the loaded drawer content
    translateLoadedPartials();
  });
} else {
  // No drawer element, mark as loaded to unblock mobile nav
  drawerLoaded = true;
  tryInitMobileNav();
}
loadPartial('footer', '/partials/footer.html', function() {
  // Set current year in footer
  const yearElement = document.getElementById('year');
  if (yearElement) {
    yearElement.textContent = new Date().getFullYear();
  }
  
  // Theme selector logic
  const themeSelect = document.getElementById('footerThemeSelect');
  if (themeSelect) {
    const savedTheme = localStorage.getItem('theme');
    themeSelect.value = savedTheme || 'system';
    
    themeSelect.addEventListener('change', (e) => {
      const val = e.target.value;
      if (val === 'system') {
        localStorage.removeItem('theme');
        const prefersDark = window.matchMedia('(prefers-color-scheme: dark)');
        if (prefersDark.matches) {
          document.documentElement.setAttribute('data-theme', 'dark');
        } else {
          document.documentElement.setAttribute('data-theme', 'light');
        }
      } else {
        localStorage.setItem('theme', val);
        document.documentElement.setAttribute('data-theme', val);
      }
    });
  }

  // Language selector logic
  const languageSelect = document.getElementById('footerLanguageSelect');
  if (languageSelect && window.languageManager) {
    languageSelect.value = window.languageManager.currentLanguage;
    languageSelect.addEventListener('change', (e) => {
      window.languageManager.setLanguage(e.target.value);
    });
  }
  
  // Translate the loaded footer content
  translateLoadedPartials();
  
  // Dispatch event when all partials are loaded
  document.dispatchEvent(new CustomEvent('partialsLoaded'));
});
