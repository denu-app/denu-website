/**
 * Environment-aware Flutter route linker for Denu (aglaea)
 * - Detects environment from hostname (local, dev, qa, uat, prod)
 * - Builds Flutter base URL for that environment (e.g., dev.app.<root-domain>)
 * - Rewrites anchors with class 'flutter-link' using data-flutter-path
 * - Propagates non-English language via ?lang=<code>
 */
(function() {
  try {
    class EnvironmentRedirect {
      constructor() {
        this.currentEnvironment = this.detectEnvironment();
        this.rootDomain = this.getRootDomain();
        this.isSetup = false;
        this.setupListeners();
        this.setupFlutterLinks();
      }

      detectEnvironment() {
        const host = window.location.hostname;
        if (host === 'localhost' || /^127\.0\.0\.1$/.test(host)) return 'local';
        if (/^dev\./.test(host)) return 'dev';
        if (/^qa\./.test(host)) return 'qa';
        if (/^uat\./.test(host)) return 'uat';
        return 'prod';
      }

      getRootDomain() {
        const host = window.location.hostname;
        const parts = host.split('.');
        if (host === 'localhost' || /^\d+\.\d+\.\d+\.\d+$/.test(host)) return host;
        if (parts.length <= 2) return host;
        return parts.slice(-2).join('.');
      }

      getFlutterBase() {
        const env = this.currentEnvironment;
        const root = this.rootDomain;
        if (env === 'local') {
          // For local, ALWAYS check if there's an override configured first
          const override = this.getLocalOverrideOriginSync();
          if (override) {
            console.log('[EnvironmentRedirect] Using override origin:', override);
            return override;
          }
          
          // If no override and we're on a different port than typical web server ports,
          // assume we're already on the Flutter dev server
          const currentPort = window.location.port;
          if (currentPort && !['80', '443', '8080', '8081', '3000', '5000', '5500'].includes(currentPort)) {
            const sameOrigin = `${window.location.protocol}//${window.location.host}`;
            console.log('[EnvironmentRedirect] Already on Flutter dev server:', sameOrigin);
            return sameOrigin;
          }
          
          // Otherwise, warn that Flutter origin is not configured
          console.warn('[EnvironmentRedirect] No Flutter origin configured for local development!');
          console.warn('[EnvironmentRedirect] Please set FLUTTER_LOCAL_ORIGIN or use ?flutter_port=XXXX parameter');
          // Return same origin as fallback
          const fallback = `${window.location.protocol}//${window.location.host}`;
          console.log('[EnvironmentRedirect] Using fallback same origin:', fallback);
          return fallback;
        }
        const prefix = env === 'prod' ? '' : `${env}.`;
        const url = `https://${prefix}app.${root}`;
        console.log('[EnvironmentRedirect] Using environment URL:', url);
        return url;
      }

      getLocalOverrideOriginSync() {
        // 1) Window global
        if (window.FLUTTER_LOCAL_ORIGIN) return window.FLUTTER_LOCAL_ORIGIN;
        // 2) localStorage
        const fromStorage = localStorage.getItem('flutter_local_origin');
        if (fromStorage) return fromStorage;
        // 3) Meta tag
        const meta = document.querySelector('meta[name="flutter-local-origin"]');
        if (meta && meta.content) return meta.content;
        // 4) URL params
        const params = new URLSearchParams(window.location.search);
        const fromParam = params.get('flutter_origin');
        if (fromParam) return fromParam;
        const portParam = params.get('flutter_port');
        if (portParam) return `${window.location.protocol}//localhost:${portParam}`;
        return null;
      }


      getCurrentLanguage() {
        if (window.languageManager && window.languageManager.currentLanguage) {
          return window.languageManager.currentLanguage;
        }
        const params = new URLSearchParams(window.location.search);
        const fromUrl = params.get('lang');
        if (fromUrl) return fromUrl;
        const fromStorage = localStorage.getItem('language');
        return fromStorage || 'en';
      }

      getFlutterUrl(routePath) {
        const base = this.getFlutterBase();
        const path = routePath ? (routePath.startsWith('/') ? routePath : `/${routePath}`) : '/';
        let url = base + path;
        const lang = this.getCurrentLanguage();
        if (lang && lang !== 'en') {
          const sep = url.includes('?') ? '&' : '?';
          url += `${sep}lang=${lang}`;
        }
        return url;
      }

      setupFlutterLinks() {
        if (this.isSetup) return;
        const links = document.querySelectorAll('a.flutter-link:not([data-env-redirect-setup])');
        console.log(`[EnvironmentRedirect] Found ${links.length} flutter-link elements`);
        links.forEach(link => {
          const routePath = link.getAttribute('data-flutter-path') || link.getAttribute('href') || '/';
          const newUrl = this.getFlutterUrl(routePath);
          console.log(`[EnvironmentRedirect] Setting up link: ${routePath} -> ${newUrl}`);
          link.href = newUrl;
          if (link.hostname !== window.location.hostname) {
            link.target = '_blank';
            link.rel = link.rel ? `${link.rel} noopener` : 'noopener';
          }
          // Always recompute on click to use latest detected origin
          link.addEventListener('click', (e) => {
            try {
              const rp = link.getAttribute('data-flutter-path') || link.getAttribute('href') || '/';
              const url = this.getFlutterUrl(rp);
              console.log(`[EnvironmentRedirect] Click handler computed URL: ${url}`);
              // Ensure opening external URL even if href was stale
              const flutterBase = this.getFlutterBase();
              if (url !== link.href || !url.startsWith(flutterBase)) {
                e.preventDefault();
                console.log(`[EnvironmentRedirect] Opening URL in new tab: ${url}`);
                window.open(url, link.target || '_blank');
              }
            } catch(_) {}
          }, { passive: false });
          link.setAttribute('data-env-redirect-setup', 'true');
        });
        // Only mark as setup if we actually found and processed links
        if (links.length > 0) {
          this.isSetup = true;
        }
      }

      refreshFlutterLinks() {
        const links = document.querySelectorAll('a.flutter-link[data-env-redirect-setup]');
        links.forEach(link => {
          const routePath = link.getAttribute('data-flutter-path') || link.getAttribute('href') || '/';
          link.href = this.getFlutterUrl(routePath);
        });
      }

      setupListeners() {
        document.addEventListener('languageChanged', () => {
          this.refreshFlutterLinks();
        });
        document.addEventListener('partialsLoaded', () => {
          // Remove setup markers from all links to allow reprocessing
          document.querySelectorAll('a.flutter-link[data-env-redirect-setup]').forEach(link => {
            link.removeAttribute('data-env-redirect-setup');
          });
          this.isSetup = false;
          this.setupFlutterLinks();
          this.refreshFlutterLinks();
        });
        document.addEventListener('DOMContentLoaded', () => {
          this.isSetup = false;
          this.setupFlutterLinks();
          this.refreshFlutterLinks();
        });
        if (document.readyState !== 'loading') {
          this.isSetup = false;
          this.setupFlutterLinks();
          this.refreshFlutterLinks();
        }
      }
    }

    window.environmentRedirect = new EnvironmentRedirect();
  } catch (e) {
    console.error('Environment redirect initialization failed:', e);
  }
})();


