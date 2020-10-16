import { postData } from './base';

// Delete old cookies
document.querySelectorAll('.disconnect-button').forEach(function(btn){

  btn.addEventListener("click", function (e) {
    postData('/session/destroy', { browser_id: e.target.dataset.browserId })
      .then(data => {
        // console.log(data); // JSON data parsed by `data.json()` call
        // TODO: Don't want to deal with state management now. Just refresh.
        window.location = '/security'
    });
  });
});