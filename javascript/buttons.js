// Remote call
document.querySelectorAll('.remote-buttons button').forEach(function(btn){

  let parentNode = btn.parent();
  let remoteUrl = parentNode.dataset.remoteUrl;
  
  btn.addEventListener("click", function (e) {
    // debugger;
    let payload = { 
      [e.target.dataset.settingName]: e.target.dataset.settingValue
    }
    
    postData(remoteUrl, payload)
      .then(data => {
        // TODO: Don't want to deal with state management now. Just refresh.
        window.location = '/security'
    });
  });
});


