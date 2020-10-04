import { postData } from './base';

// Delete old cookies
document.querySelectorAll('.disconnect-button').forEach(function(btn){

  btn.addEventListener("click", function (e) {
    // debugger;
    postData('/session/destroy', { public_id: e.target.dataset.publicId })
      .then(data => {
        // console.log(data); // JSON data parsed by `data.json()` call
        // TODO: Don't want to deal with state management now. Just refresh.
        window.location = '/security'
    });
  });
});
  
