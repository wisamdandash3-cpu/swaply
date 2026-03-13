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
})();
