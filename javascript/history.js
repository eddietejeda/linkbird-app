// Remote call
import { postData, getAll } from './base';

document.querySelectorAll('.history-action').forEach( btn => {
    
  let tweetId = btn.dataset.tweetId;
  
  btn.addEventListener("click", function (e) {
    let payload = { 
      tweet_id: tweetId
    }
    postData("/history/update", payload).then(data => {
      console.log(data);
    });
  });

});
  
  
  