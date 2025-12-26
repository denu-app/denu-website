/**
 * Mobile Navigation - Hamburger menu functionality
 */

window.initMobileNav = function() {
  const hamburger = document.getElementById('hamburger');
  const mobileNavDrawer = document.getElementById('mobileNavDrawer');
  const mobileNavOverlay = document.getElementById('mobileNavOverlay');
  const mobileNavClose = document.getElementById('mobileNavClose');

  if (!hamburger) {
    console.log('[MobileNav] Hamburger element not found');
    return;
  }

  // Open drawer
  function openDrawer() {
    if (mobileNavDrawer) mobileNavDrawer.classList.add('active');
    if (mobileNavOverlay) mobileNavOverlay.classList.add('active');
    document.body.style.overflow = 'hidden';
  }

  // Close drawer
  function closeDrawer() {
    if (mobileNavDrawer) mobileNavDrawer.classList.remove('active');
    if (mobileNavOverlay) mobileNavOverlay.classList.remove('active');
    document.body.style.overflow = '';
  }

  // Event listeners
  hamburger.addEventListener('click', openDrawer);
  
  if (mobileNavClose) {
    mobileNavClose.addEventListener('click', closeDrawer);
  }
  
  if (mobileNavOverlay) {
    mobileNavOverlay.addEventListener('click', closeDrawer);
  }

  // Close drawer when clicking on links
  if (mobileNavDrawer) {
    const links = mobileNavDrawer.querySelectorAll('a');
    links.forEach(link => {
      link.addEventListener('click', closeDrawer);
    });
  }

  console.log('[MobileNav] Initialized');
};


