/* Center City Gym — interactions */

/* Year */
document.getElementById('yr').textContent = new Date().getFullYear();

/* Nav: scrolled state + mobile toggle */
const nav = document.getElementById('nav');
const toggle = document.getElementById('navToggle');
const links = document.getElementById('navLinks');
const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 20);
onScroll();
window.addEventListener('scroll', onScroll, { passive: true });

const closeMenu = () => {
  links.classList.remove('open');
  toggle.classList.remove('open');
  toggle.setAttribute('aria-expanded', 'false');
};
toggle.addEventListener('click', () => {
  const open = links.classList.toggle('open');
  toggle.classList.toggle('open', open);
  toggle.setAttribute('aria-expanded', open ? 'true' : 'false');
});
links.querySelectorAll('a').forEach(a => a.addEventListener('click', closeMenu));

/* Scroll reveal */
const io = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); }
  });
}, { threshold: 0.12, rootMargin: '0px 0px -40px 0px' });
document.querySelectorAll('.reveal').forEach(el => io.observe(el));

/* Animated counters */
const fmt = (n) => n.toLocaleString('en-US');
const animateCount = (el) => {
  const target = +el.dataset.count;
  const prefix = el.dataset.prefix || '';
  const suffix = el.dataset.suffix || '';
  const dur = 1500;
  const start = performance.now();
  const step = (now) => {
    const p = Math.min((now - start) / dur, 1);
    const eased = 1 - Math.pow(1 - p, 3);
    el.textContent = prefix + fmt(Math.round(target * eased)) + suffix;
    if (p < 1) requestAnimationFrame(step);
  };
  requestAnimationFrame(step);
};
const countIO = new IntersectionObserver((entries) => {
  entries.forEach(e => {
    if (e.isIntersecting) { animateCount(e.target); countIO.unobserve(e.target); }
  });
}, { threshold: 0.6 });
document.querySelectorAll('.num[data-count]').forEach(el => countIO.observe(el));

/* FAQ accordion */
document.querySelectorAll('.faq-q').forEach(btn => {
  btn.addEventListener('click', () => {
    const item = btn.parentElement;
    const ans = item.querySelector('.faq-a');
    const isOpen = item.classList.contains('open');
    document.querySelectorAll('.faq-item.open').forEach(o => {
      o.classList.remove('open');
      o.querySelector('.faq-a').style.maxHeight = null;
    });
    if (!isOpen) { item.classList.add('open'); ans.style.maxHeight = ans.scrollHeight + 'px'; }
  });
});

/* Back to top */
const toTop = document.getElementById('toTop');
const topScroll = () => toTop.classList.toggle('show', window.scrollY > 600);
topScroll();
window.addEventListener('scroll', topScroll, { passive: true });
toTop.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));

/* Contact form via Formspree (graceful, no page reload) */
const form = document.getElementById('contactForm');
const note = document.getElementById('formNote');
const sendBtn = document.getElementById('sendBtn');
form.addEventListener('submit', async (e) => {
  e.preventDefault();
  note.className = 'form-note';
  note.textContent = '';
  // If the Formspree endpoint hasn't been configured yet, guide the owner instead of failing silently.
  if (form.action.includes('your_form_id')) {
    note.classList.add('err');
    note.textContent = 'Form not connected yet — add your Formspree form ID to enable sending.';
    return;
  }
  sendBtn.disabled = true;
  sendBtn.textContent = 'Sending…';
  try {
    const res = await fetch(form.action, {
      method: 'POST',
      body: new FormData(form),
      headers: { 'Accept': 'application/json' }
    });
    if (res.ok) {
      form.reset();
      note.classList.add('ok');
      note.textContent = 'Thanks for reaching out — we\'ll get back to you soon!';
    } else {
      note.classList.add('err');
      note.textContent = 'Something went wrong. Please call us at (231) 487-1205.';
    }
  } catch {
    note.classList.add('err');
    note.textContent = 'Network error. Please call us at (231) 487-1205.';
  } finally {
    sendBtn.disabled = false;
    sendBtn.textContent = 'Send Message';
  }
});
