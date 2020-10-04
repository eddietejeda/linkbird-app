// Modals
import {postData, getAll} from './base';

var rootEl = document.documentElement;
var $modals = getAll('.modal');
var $modalButtons = getAll('.modal-button');
var $modalCloses = getAll('.modal-background, .modal-close, .modal-card-head .delete, .modal-card-foot .button');

if ($modalButtons.length > 0) {
  $modalButtons.forEach(function ($el) {
    $el.addEventListener('click', function () {
      var target = $el.dataset.target;
      openModal(target);
    });
  });
}

if ($modalCloses.length > 0) {
  $modalCloses.forEach(function ($el) {
    $el.addEventListener('click', function () {
      closeModals();
    });
  });
}

function openModal(target) {
  var modal = document.getElementById(target);
  rootEl.classList.add('is-clipped');
  modal.classList.add('is-active');
}

function closeModals() {
  rootEl.classList.remove('is-clipped');
  $modals.forEach(function ($el) {
    $el.classList.remove('is-active');
  });
}

document.addEventListener('keydown', function (event) {
  var e = event || window.event;
  if (e.keyCode === 27) {
    closeModals();
    closeDropdowns();
  }
});

// Use backup image with Favicon does not load
document.querySelectorAll('.toggle-settings-button').forEach(function(btn){

  btn.addEventListener("click", function (e) {

    let isPremiumUser = document.getElementById( 'is-premium-user').value == "true" ? true : false
    let isPremiumFeature = e.target.classList.contains('premium-feature')

    if (!isPremiumFeature || (isPremiumUser && isPremiumFeature) ){
      let payload = {}
      payload[e.target.dataset.settingName] = e.target.value; // Validation happens server side

      postData('/settings/update', payload )
      .then(data => {
        // console.log(data); // JSON data parsed by `data.json()` call
        // TODO: Don't want to deal with state management now. Just refresh.
        window.location = '/profile';
      });
    }
    else{
      openModal("premium-modal");
    }  
  });
});