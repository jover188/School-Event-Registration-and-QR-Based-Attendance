/**
 * Attendify — Official Landing Page JavaScript
 * Vanilla JS, Zero Dependencies, Accessible & Performant
 */

document.addEventListener('DOMContentLoaded', () => {
  initMobileMenu();
  initSmoothScroll();
  initRoleTabs();
  initScrollSpy();
});

/**
 * 1. Mobile Navigation Toggle
 */
function initMobileMenu() {
  const toggleBtn = document.getElementById('mobileMenuToggle');
  const overlay = document.getElementById('mobileNavOverlay');
  const navLinks = document.querySelectorAll('.mobile-nav-link, .mobile-nav-action');

  if (!toggleBtn || !overlay) return;

  function toggleMenu(show) {
    const isExpanded = show !== undefined ? show : overlay.classList.toggle('active');
    overlay.classList.toggle('active', isExpanded);
    toggleBtn.setAttribute('aria-expanded', isExpanded ? 'true' : 'false');
    document.body.style.overflow = isExpanded ? 'hidden' : '';

    // Update hamburger icon
    const icon = toggleBtn.querySelector('svg');
    if (icon) {
      if (isExpanded) {
        icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>';
      } else {
        icon.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16m-7 6h7"/>';
      }
    }
  }

  toggleBtn.addEventListener('click', () => toggleMenu());

  navLinks.forEach((link) => {
    link.addEventListener('click', () => toggleMenu(false));
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && overlay.classList.contains('active')) {
      toggleMenu(false);
    }
  });
}

/**
 * 2. Smooth Scrolling for Anchor Links
 */
function initSmoothScroll() {
  document.querySelectorAll('a[href^="#"]').forEach((anchor) => {
    anchor.addEventListener('click', function (e) {
      const targetId = this.getAttribute('href');
      if (targetId === '#' || !targetId) return;

      const targetEl = document.querySelector(targetId);
      if (targetEl) {
        e.preventDefault();
        targetEl.scrollIntoView({
          behavior: 'smooth',
          block: 'start',
        });
        window.history.pushState(null, '', targetId);
      }
    });
  });
}

/**
 * 3. Application Preview Role Tabs
 */
function initRoleTabs() {
  const tabButtons = document.querySelectorAll('.role-tab-btn');
  const tabPanels = document.querySelectorAll('.preview-role-panel');

  if (!tabButtons.length || !tabPanels.length) return;

  tabButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetRole = btn.getAttribute('data-role');

      tabButtons.forEach((b) => b.classList.remove('active'));
      tabPanels.forEach((p) => p.classList.remove('active'));

      btn.classList.add('active');
      const targetPanel = document.getElementById(`role-panel-${targetRole}`);
      if (targetPanel) {
        targetPanel.classList.add('active');
      }
    });
  });
}

/**
 * 4. Scroll Spy for Active Navigation Highlight
 */
function initScrollSpy() {
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links .nav-link');

  if (!sections.length || !navLinks.length) return;

  const observerOptions = {
    root: null,
    rootMargin: '-30% 0px -60% 0px',
    threshold: 0,
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const id = entry.target.getAttribute('id');
        navLinks.forEach((link) => {
          const href = link.getAttribute('href');
          if (href === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });
      }
    });
  }, observerOptions);

  sections.forEach((sec) => observer.observe(sec));
}
