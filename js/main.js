/* ═══════════════════════════════════════════════════════
   MAIN.JS — FlowrA Technology Africa Limited
═══════════════════════════════════════════════════════ */
(function () {
  'use strict';

  /* ── Loader ──────────────────────────────────────────── */
  const loader = document.getElementById('loader');
  window.addEventListener('load', () => {
    setTimeout(() => {
      loader.classList.add('out');
      setTimeout(() => { loader.style.display = 'none'; }, 750);
    }, 1500);
  });

  /* ── Theme Toggle ────────────────────────────────────── */
  const html     = document.documentElement;
  const themeBtn = document.getElementById('theme-toggle');

  const saved = localStorage.getItem('flowra-theme') ||
    (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');
  html.setAttribute('data-theme', saved);

  if (themeBtn) {
    themeBtn.addEventListener('click', () => {
      const next = html.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
      html.setAttribute('data-theme', next);
      localStorage.setItem('flowra-theme', next);
    });
  }

  /* ── Progress Bar ────────────────────────────────────── */
  const progressBar = document.getElementById('progress-bar');
  const scrollTop   = document.getElementById('scroll-top');

  window.addEventListener('scroll', () => {
    const scrolled  = window.scrollY;
    const docHeight = document.documentElement.scrollHeight - window.innerHeight;
    if (progressBar) progressBar.style.width = (docHeight > 0 ? (scrolled / docHeight) * 100 : 0) + '%';
    if (scrollTop)   scrollTop.classList.toggle('vis', scrolled > 500);
  }, { passive: true });

  /* ── Nav scroll state ────────────────────────────────── */
  const nav = document.getElementById('nav');
  window.addEventListener('scroll', () => {
    if (nav) nav.classList.toggle('scrolled', window.scrollY > 24);
  }, { passive: true });

  /* ── Mobile menu ─────────────────────────────────────── */
  const ham     = document.getElementById('ham');
  const mobMenu = document.getElementById('mob-menu');
  let menuOpen  = false;

  if (ham && mobMenu) {
    ham.addEventListener('click', () => {
      menuOpen = !menuOpen;
      mobMenu.classList.toggle('open', menuOpen);
      ham.setAttribute('aria-expanded', String(menuOpen));
      const spans = ham.querySelectorAll('span');
      spans[0].style.transform = menuOpen ? 'translateY(7px) rotate(45deg)' : '';
      spans[1].style.opacity   = menuOpen ? '0' : '';
      spans[2].style.transform = menuOpen ? 'translateY(-7px) rotate(-45deg)' : '';
    });
  }

  function closeMob() {
    if (!menuOpen) return;
    menuOpen = false;
    mobMenu.classList.remove('open');
    ham.setAttribute('aria-expanded', 'false');
    const spans = ham.querySelectorAll('span');
    spans[0].style.transform = spans[2].style.transform = spans[1].style.opacity = '';
  }
  if (mobMenu) {
    mobMenu.querySelectorAll('a').forEach(a => a.addEventListener('click', closeMob));
  }

  if (scrollTop) {
    scrollTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
  }

  /* ── Scroll Reveal ───────────────────────────────────── */
  const revealObs = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('visible');
        revealObs.unobserve(e.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -50px 0px' });

  document.querySelectorAll('.reveal, .reveal-group').forEach(el => revealObs.observe(el));

  /* ── Counter Animation ───────────────────────────────── */
  function animateCounter(el) {
    const target   = parseFloat(el.dataset.target);
    const suffix   = el.dataset.suffix || '';
    const decimal  = el.dataset.decimal === 'true';
    const duration = 1800;
    const start    = performance.now();

    function step(now) {
      const progress = Math.min((now - start) / duration, 1);
      const eased    = 1 - Math.pow(1 - progress, 3);
      const current  = eased * target;
      el.textContent = (decimal ? current.toFixed(1) : Math.floor(current)) + suffix;
      if (progress < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }

  const counterObs = new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting && !e.target.classList.contains('counted')) {
        e.target.classList.add('counted');
        animateCounter(e.target);
        counterObs.unobserve(e.target);
      }
    });
  }, { threshold: 0.6 });

  document.querySelectorAll('.counter').forEach(el => counterObs.observe(el));

  /* ── 3D Card Tilt ────────────────────────────────────── */
  document.querySelectorAll('.card-tilt').forEach(card => {
    card.addEventListener('mousemove', e => {
      const r = card.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width  - 0.5;
      const y = (e.clientY - r.top)  / r.height - 0.5;
      card.style.transition = 'transform 0.08s ease, box-shadow 0.08s ease';
      card.style.transform  = `perspective(900px) rotateY(${x * 10}deg) rotateX(${-y * 7}deg) translateZ(8px)`;
    });
    card.addEventListener('mouseleave', () => {
      card.style.transition = 'transform 0.55s ease, box-shadow 0.55s ease';
      card.style.transform  = '';
    });
  });

  /* ── Active nav highlight ────────────────────────────── */
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('.nav-links a:not(.nav-cta)');

  new IntersectionObserver(entries => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        navLinks.forEach(a => {
          const active = a.getAttribute('href') === '#' + e.target.id;
          a.style.color      = active ? 'var(--navy)' : '';
          a.style.fontWeight = active ? '800' : '';
        });
      }
    });
  }, { rootMargin: '-35% 0px -60% 0px' }).observe && sections.forEach(s =>
    new IntersectionObserver(entries => {
      if (entries[0].isIntersecting) {
        navLinks.forEach(a => {
          const active = a.getAttribute('href') === '#' + s.id;
          a.style.color      = active ? 'var(--navy)' : '';
          a.style.fontWeight = active ? '800' : '';
        });
      }
    }, { rootMargin: '-35% 0px -60% 0px' }).observe(s)
  );

  /* ── Contact Form ────────────────────────────────────── */
  const form  = document.getElementById('contact-form');
  const toast = document.getElementById('toast');

  function showToast(msg) {
    const msgEl = toast.querySelector('.toast-msg');
    if (msgEl) msgEl.textContent = msg;
    toast.classList.add('show');
    setTimeout(() => toast.classList.remove('show'), 4800);
  }

  if (form) {
    const FALLBACK = 'Please email business@flowratech.com directly.';

    form.addEventListener('submit', function (e) {
      e.preventDefault();
      const btn  = form.querySelector('.submit-btn');
      const orig = btn.textContent;

      // hCaptcha token is required; Web3Forms verifies it server-side
      // (enable "Block Spam → hCaptcha" in the Web3Forms dashboard).
      const token = form.querySelector('textarea[name="h-captcha-response"]');
      if (!token || !token.value) {
        showToast('Please tick the "I am human" box before sending.');
        return;
      }

      btn.textContent = 'Sending…';
      btn.disabled    = true;

      fetch('https://api.web3forms.com/submit', {
        method: 'POST',
        body:   new FormData(form)
      })
      .then(function (res) {
        // Name the real cause; never mislabel a 4xx/5xx as a network error.
        if (res.status === 429) throw new Error('Too many messages sent from this network. Wait a few minutes or ' + FALLBACK);
        if (res.status >= 500)  throw new Error('Our form service is down right now. ' + FALLBACK);
        return res.json().catch(function () {
          throw new Error('Unexpected reply from the form service (HTTP ' + res.status + '). ' + FALLBACK);
        });
      })
      .then(function (json) {
        if (json && json.success) {
          form.reset();
          if (window.hcaptcha) { try { window.hcaptcha.reset(); } catch (_) {} }
          showToast('Message sent! We\'ll respond within 24 hours. ✓');
        } else {
          throw new Error((json && json.message ? json.message + '. ' : 'Form was rejected. ') + FALLBACK);
        }
      })
      .catch(function (err) {
        const msg = (err && err.message) ? err.message : '';
        showToast(msg && !/Failed to fetch|NetworkError|Load failed/i.test(msg)
          ? msg
          : 'No connection to the form service. Check your internet or ' + FALLBACK);
        if (window.hcaptcha) { try { window.hcaptcha.reset(); } catch (_) {} }
      })
      .finally(function () {
        btn.textContent = orig;
        btn.disabled    = false;
      });
    });
  }

  /* ── WhatsApp message loop ───────────────────────────── */
  const waBody = document.getElementById('wa-messages');
  if (waBody) {
    setInterval(() => {
      const msgs = waBody.querySelectorAll('.wa-msg');
      msgs.forEach(m => {
        m.style.animation = 'none';
        m.style.opacity   = '0';
      });
      void waBody.offsetHeight;
      msgs.forEach(m => {
        m.style.animation = '';
        m.style.opacity   = '';
      });
    }, 9000);
  }

  /* ── Dark mode nav link color fix ───────────────────── */
  function updateNavLinkColors() {
    const isDark = html.getAttribute('data-theme') === 'dark';
    navLinks.forEach(a => {
      if (!a.style.color) {
        a.style.color = isDark ? 'var(--text-mid)' : '';
      }
    });
  }
  const themeObserver = new MutationObserver(updateNavLinkColors);
  themeObserver.observe(html, { attributes: true, attributeFilter: ['data-theme'] });

})();
