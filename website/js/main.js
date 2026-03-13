(function () {
  'use strict';

  // Language dropdown toggle
  var trigger = document.querySelector('.lang-trigger');
  var menu = document.querySelector('.lang-menu');
  var dropdown = document.querySelector('.lang-dropdown');

  if (trigger && menu) {
    trigger.addEventListener('click', function () {
      var isOpen = dropdown.classList.contains('open');
      dropdown.classList.toggle('open');
      menu.hidden = isOpen;
      trigger.setAttribute('aria-expanded', !isOpen);
    });

    document.addEventListener('click', function (e) {
      if (!dropdown.contains(e.target)) {
        dropdown.classList.remove('open');
        menu.hidden = true;
        trigger.setAttribute('aria-expanded', 'false');
      }
    });
  }

  // Optional: when a language is selected, update trigger text
  var langButtons = document.querySelectorAll('.lang-menu button');
  langButtons.forEach(function (btn) {
    btn.addEventListener('click', function () {
      if (trigger) trigger.textContent = btn.textContent;
      if (menu) menu.hidden = true;
      if (dropdown) dropdown.classList.remove('open');
    });
  });

  // Reviews carousel: زرّي Prev/Next
  var carousel = document.querySelector('.reviews-carousel');
  var cards = carousel ? carousel.querySelectorAll('.review-card') : [];
  var dots = document.querySelectorAll('.reviews-section .carousel-dots .dot');
  var prevBtn = document.querySelector('.reviews-carousel-wrap .prev');
  var nextBtn = document.querySelector('.reviews-carousel-wrap .next');
  var currentSlide = 0;

  function setSlide(i) {
    if (!carousel || !cards.length) return;
    currentSlide = Math.max(0, Math.min(i, cards.length - 1));
    carousel.style.transform = 'translateX(-' + (currentSlide * 100) + '%)';
    dots.forEach(function (d, j) { d.classList.toggle('active', j === currentSlide); });
  }

  if (prevBtn) prevBtn.addEventListener('click', function () { setSlide(currentSlide - 1); });
  if (nextBtn) nextBtn.addEventListener('click', function () { setSlide(currentSlide + 1); });
  dots.forEach(function (d, i) { d.addEventListener('click', function () { setSlide(i); }); });

  if (carousel && cards.length) {
    carousel.style.display = 'flex';
    carousel.style.width = (cards.length * 100) + '%';
    cards.forEach(function (c) { c.style.flex = '0 0 ' + (100 / cards.length) + '%'; });
    setSlide(0);
  }
})();
