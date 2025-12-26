// Language Manager for Denu Website
class LanguageManager {
  constructor() {
    this.translations = this.loadTranslations();
    this.currentLanguage = this.getLanguageFromURL() || this.getStoredLanguage() || this.detectBrowserLanguage();
    this.init();
  }

  // Get language from URL parameter
  getLanguageFromURL() {
    const urlParams = new URLSearchParams(window.location.search);
    const langParam = urlParams.get('lang');
    if (langParam && this.translations && this.translations[langParam]) {
      return langParam;
    }
    return null;
  }

  // Enhanced browser language detection with geographic support
  detectBrowserLanguage() {
    // 1. Check for stored language preference first
    const storedLang = this.getStoredLanguage();
    if (storedLang && this.translations[storedLang]) {
      return storedLang;
    }

    // 2. Check navigator.languages array (more accurate)
    if (navigator.languages && navigator.languages.length > 0) {
      for (const lang of navigator.languages) {
        const primaryLang = lang.split('-')[0];
        if (this.translations[primaryLang]) {
          return primaryLang;
        }
      }
    }

    // 3. Check navigator.language
    const browserLang = navigator.language || navigator.userLanguage;
    if (browserLang) {
      const primaryLang = browserLang.split('-')[0];
      if (this.translations[primaryLang]) {
        return primaryLang;
      }
    }

    // 4. Check for Iran location based on timezone
    if (this.isIranLocation()) {
      return 'fa';
    }

    // 5. Default to English
    return 'en';
  }

  // Check if user is likely in Iran based on timezone
  isIranLocation() {
    try {
      const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;
      return timezone === 'Asia/Tehran';
    } catch (e) {
      return false;
    }
  }

  // Get stored language from localStorage
  getStoredLanguage() {
    return localStorage.getItem('language');
  }

  // Store language preference
  setStoredLanguage(lang) {
    localStorage.setItem('language', lang);
  }

  // Load translation data
  loadTranslations() {
    return {
      en: {
        // Navigation
        'nav.home': 'Home',
        'nav.products': 'Products',
        'nav.developers': 'Developers',
        'nav.resources': 'Resources',
        'nav.api': 'API',
        'nav.dashboard': 'Dashboard',
        'nav.docs': 'Documentation',
        'nav.sdk': 'SDKs',
        'nav.about': 'About Us',
        'nav.pricing': 'Pricing',
        'nav.contact': 'Contact Us',
        'nav.sign-in': 'Login'  ,
        'nav.sign-up': 'Get Started for Free',
        'nav.request-demo': 'Request Demo',
        'nav.discover': 'Discover Places',

        // Footer
        'footer.products': 'Products',
        'footer.developers': 'Developers',
        'footer.resources': 'Resources',
        'footer.description': 'AI-powered location-based discovery platform that helps you find amazing places around you. Discover restaurants, cafes, attractions, and hidden gems with intelligent recommendations.',
        'footer.company': 'Built by',
        'footer.company-desc': 'Denu is an innovative location discovery platform designed to revolutionize how people explore their surroundings.',
        'footer.privacy': 'Privacy Policy',
        'footer.terms': 'Terms of Service',
        'footer.copyright': 'All rights reserved.',

        // Homepage
        'home.hero.title': 'Discover Amazing Places Around You',
        'home.hero.subtitle': 'Find the best restaurants, cafes, attractions, and hidden gems in your area with AI-powered recommendations.',
        'home.hero.cta': 'Start Exploring',
        'home.hero.learn-more': 'Learn More',
        'home.features.title': 'Why Choose Denu?',
        'home.features.discovery.title': 'Smart Discovery',
        'home.features.discovery.desc': 'AI-powered recommendations based on your preferences and location.',
        'home.features.local.title': 'Local Expertise',
        'home.features.local.desc': 'Discover hidden gems and local favorites that tourists miss.',
        'home.features.reviews.title': 'Real Reviews',
        'home.features.reviews.desc': 'Read authentic reviews from real people who have been there.',

        // About Page
        'about.hero.title': 'About Denu',
        'about.hero.subtitle': 'We\'re revolutionizing how people discover amazing places around them.',
        'about.mission.title': 'Our Mission',
        'about.mission.desc': 'To help people discover the best places around them through intelligent recommendations and local insights.',
        'about.vision.title': 'Our Vision',
        'about.vision.desc': 'A world where everyone can easily find and enjoy the best experiences in their local area.',

        // Contact Page
        'contact.hero.title': 'Get in Touch',
        'contact.hero.subtitle': 'Have questions or feedback? We\'d love to hear from you.',
        'contact.form.name': 'Your Name',
        'contact.form.email': 'Email Address',
        'contact.form.message': 'Message',
        'contact.form.submit': 'Send Message',

        // Privacy Policy
        'privacy.title': 'Privacy Policy',
        'privacy.intro': 'Your privacy is important to us. This policy explains how we collect, use, and protect your information.',
        'privacy.collection.title': 'Information We Collect',
        'privacy.collection.desc': 'We collect information you provide directly to us and information automatically collected when you use our service.',
        'privacy.use.title': 'How We Use Your Information',
        'privacy.use.desc': 'We use your information to provide, maintain, and improve our services.',

        // Terms of Service
        'terms.title': 'Terms of Service',
        'terms.intro': 'These terms govern your use of our service. By using Denu, you agree to these terms.',
        'terms.acceptance.title': 'Acceptance of Terms',
        'terms.acceptance.desc': 'By accessing or using our service, you agree to be bound by these terms.',
        'terms.use.title': 'Use of Service',
        'terms.use.desc': 'You may use our service for lawful purposes only and in accordance with these terms.'
      },
      fa: {
        // Navigation
        'nav.home': 'خانه',
        'nav.products': 'محصولات',
        'nav.developers': 'توسعه‌دهندگان',
        'nav.resources': 'منابع',
        'nav.api': 'API',
        'nav.dashboard': 'داشبورد',
        'nav.docs': 'مستندات',
        'nav.sdk': 'SDK ها',
        'nav.about': 'درباره دنو',
        'nav.pricing': 'قیمت‌گذاری',
        'nav.contact': 'تماس',
        'nav.sign-in': 'ورود',
        'nav.sign-up': 'رایگان شروع کنید',
        'nav.request-demo': 'درخواست دمو',
        'nav.discover': 'کشف مکان‌ها',

        // Footer
        'footer.products': 'محصولات',
        'footer.developers': 'توسعه‌دهندگان',
        'footer.resources': 'منابع',
        'footer.description': 'پلتفرم کشف مکان‌های جذاب با هوش مصنوعی که به شما کمک می‌کند مکان‌های فوق‌العاده اطرافتان را پیدا کنید. رستوران‌ها، کافه‌ها، جاذبه‌ها و گنجینه‌های پنهان را با توصیه‌های هوشمند کشف کنید.',
        'footer.company': 'ساخته شده توسط',
        'footer.company-desc': 'دنو یک پلتفرم نوآورانه کشف مکان است که برای انقلاب در نحوه کشف محیط اطراف مردم طراحی شده است.',
        'footer.privacy': 'سیاست حریم خصوصی',
        'footer.terms': 'شرایط استفاده',
        'footer.copyright': 'تمام حقوق محفوظ است.',

        // Homepage
        'home.hero.title': 'مکان‌های فوق‌العاده اطرافتان را کشف کنید',
        'home.hero.subtitle': 'بهترین رستوران‌ها، کافه‌ها، جاذبه‌ها و گنجینه‌های پنهان منطقه خود را با توصیه‌های هوشمند پیدا کنید.',
        'home.hero.cta': 'شروع کاوش',
        'home.hero.learn-more': 'بیشتر بدانید',
        'home.features.title': 'چرا دنو را انتخاب کنید؟',
        'home.features.discovery.title': 'کشف هوشمند',
        'home.features.discovery.desc': 'توصیه‌های هوشمند بر اساس ترجیحات و موقعیت شما.',
        'home.features.local.title': 'تخصص محلی',
        'home.features.local.desc': 'گنجینه‌های پنهان و علاقه‌مندی‌های محلی که گردشگران از دست می‌دهند را کشف کنید.',
        'home.features.reviews.title': 'نقدهای واقعی',
        'home.features.reviews.desc': 'نقدهای معتبر از افراد واقعی که آنجا بوده‌اند بخوانید.',

        // About Page
        'about.hero.title': 'درباره دنو',
        'about.hero.subtitle': 'ما نحوه کشف مکان‌های فوق‌العاده توسط مردم را متحول می‌کنیم.',
        'about.mission.title': 'ماموریت ما',
        'about.mission.desc': 'کمک به مردم برای کشف بهترین مکان‌های اطرافشان از طریق توصیه‌های هوشمند و بینش‌های محلی.',
        'about.vision.title': 'چشم‌انداز ما',
        'about.vision.desc': 'جهانی که در آن همه بتوانند به راحتی بهترین تجربیات منطقه خود را پیدا کنند و از آن لذت ببرند.',

        // Contact Page
        'contact.hero.title': 'تماس با ما',
        'contact.hero.subtitle': 'سوال یا نظری دارید؟ دوست داریم از شما بشنویم.',
        'contact.form.name': 'نام شما',
        'contact.form.email': 'آدرس ایمیل',
        'contact.form.message': 'پیام',
        'contact.form.submit': 'ارسال پیام',

        // Privacy Policy
        'privacy.title': 'سیاست حریم خصوصی',
        'privacy.intro': 'حریم خصوصی شما برای ما مهم است. این سیاست توضیح می‌دهد که چگونه اطلاعات شما را جمع‌آوری، استفاده و محافظت می‌کنیم.',
        'privacy.collection.title': 'اطلاعاتی که جمع‌آوری می‌کنیم',
        'privacy.collection.desc': 'ما اطلاعاتی که مستقیماً به ما ارائه می‌دهید و اطلاعاتی که هنگام استفاده از سرویس ما به طور خودکار جمع‌آوری می‌شود را جمع‌آوری می‌کنیم.',
        'privacy.use.title': 'نحوه استفاده از اطلاعات شما',
        'privacy.use.desc': 'ما از اطلاعات شما برای ارائه، نگهداری و بهبود خدماتمان استفاده می‌کنیم.',

        // Terms of Service
        'terms.title': 'شرایط استفاده',
        'terms.intro': 'این شرایط استفاده از سرویس ما را تنظیم می‌کند. با استفاده از دنو، شما با این شرایط موافقت می‌کنید.',
        'terms.acceptance.title': 'پذیرش شرایط',
        'terms.acceptance.desc': 'با دسترسی یا استفاده از سرویس ما، شما با این شرایط موافقت می‌کنید.',
        'terms.use.title': 'استفاده از سرویس',
        'terms.use.desc': 'شما می‌توانید از سرویس ما فقط برای اهداف قانونی و مطابق با این شرایط استفاده کنید.'
      }
    };
  }

  // Initialize the language manager
  init() {
    this.setLanguage(this.currentLanguage);
    this.updatePageLanguage();
    this.updateMetaTags();
  }

  // Set the current language
  setLanguage(lang) {
    if (!this.translations[lang]) {
      console.warn(`Language ${lang} not supported`);
      return;
    }

    this.currentLanguage = lang;
    this.setStoredLanguage(lang);
    this.updatePageLanguage();
    this.updateMetaTags();
    this.translatePage();
  }

  // Update page language attribute
  updatePageLanguage() {
    document.documentElement.lang = this.currentLanguage;
  }

  // Update meta tags for language
  updateMetaTags() {
    // Update canonical URL with language parameter
    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) {
      const url = new URL(canonical.href);
      if (this.currentLanguage !== 'en') {
        url.searchParams.set('lang', this.currentLanguage);
      } else {
        url.searchParams.delete('lang');
      }
      canonical.href = url.toString();
    }
  }

  // Translate all elements with data-lang attributes
  translatePage() {
    const elements = document.querySelectorAll('[data-lang]');
    elements.forEach(element => {
      const key = element.getAttribute('data-lang');
      const translation = this.translations[this.currentLanguage][key];
      
      if (translation) {
        if (element.tagName === 'INPUT' && element.type === 'text') {
          element.placeholder = translation;
        } else if (element.tagName === 'INPUT' && element.type === 'email') {
          element.placeholder = translation;
        } else if (element.tagName === 'TEXTAREA') {
          element.placeholder = translation;
        } else {
          // Check if element has icon children (Font Awesome icons)
          const icons = element.querySelectorAll('i.fas, i.far, i.fab');
          if (icons.length > 0) {
            // Preserve icons and only replace text content
            const textNodes = Array.from(element.childNodes).filter(node => 
              node.nodeType === 3 && node.textContent.trim() // Only text nodes with content
            );
            // Remove old text nodes
            textNodes.forEach(node => node.remove());
            // Insert translation text before icons or after icons
            if (icons[0].previousSibling === null) {
              // Icons come first, add text after
              icons[icons.length - 1].insertAdjacentText('afterend', translation);
            } else {
              // Icons in the middle or end
              element.insertBefore(document.createTextNode(translation), icons[0]);
            }
          } else {
            element.textContent = translation;
          }
        }
      }
    });
  }

  // Get translation for a key
  getTranslation(key) {
    return this.translations[this.currentLanguage][key] || key;
  }
}

// Initialize language manager when DOM is ready
document.addEventListener('DOMContentLoaded', function() {
  window.languageManager = new LanguageManager();
});

// Also initialize if DOM is already loaded
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', function() {
    window.languageManager = new LanguageManager();
  });
} else {
  window.languageManager = new LanguageManager();
}
