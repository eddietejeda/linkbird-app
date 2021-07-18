// Remote call
import { postData, getAll } from './base';

document.querySelectorAll('.bookmark-action').forEach( btn => {
    
  let tweetId = btn.dataset.tweetId;
  
  btn.addEventListener("click", function (e) {
    let payload = { 
      tweet_id: tweetId
    }
    postData("/bookmark/update", payload).then(data => {
      e.target.style.color = "red";
    });
  });

});
  
  
  