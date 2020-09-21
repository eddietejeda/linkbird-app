// Pull down to refresh content
// https://dev.to/vijitail/pull-to-refresh-animation-with-vanilla-javascript-17oc
const pStart = { x: 0, y: 0 };
const pCurrent = { x: 0, y: 0 };
const main = document.querySelector("body > .loading-container");

function loading() {  
  main.style.display = 'flex';
}

function swipeStart(e) {
  if (typeof e["targetTouches"] !== "undefined") {
    let touch = e.targetTouches[0];
    pStart.x = touch.screenX;
    pStart.y = touch.screenY;
  } 
  else {
    pStart.x = e.screenX;
    pStart.y = e.screenY;
  }
}

function swipeEnd(e) {
  
  fetch('/refresh');    
  setTimeout(() => {
    main.style.display = 'none';
    window.location = '/';
  }, 2000);
  
}

function swipe(e) {
  if (typeof e["changedTouches"] !== "undefined") {
    let touch = e.changedTouches[0];
    pCurrent.x = touch.screenX;
    pCurrent.y = touch.screenY;
  } 
  else {
    pCurrent.x = e.screenX;
    pCurrent.y = e.screenY;
  }
  
  let changeY = pStart.y < pCurrent.y ? Math.abs(pStart.y - pCurrent.y) : 0;
  if (document.body.scrollTop === 0) {
    if (changeY > 100) {
      loading();
    }
  }
}


document.addEventListener("touchstart", e => swipeStart(e), false);
document.addEventListener("touchmove", e => swipe(e), false);
document.addEventListener("touchend", e => swipeEnd(e), false);



// Create a Checkout Session with the selected plan ID
var createCheckoutSession = function(priceId) {
  return fetch("/create-checkout-session", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      priceId: priceId
    })
  }).then(function(result) {
    return result.json();
  });
};

// Handle any errors returned from Checkout
var handleResult = function(result) {
  if (result.error) {
    console.log(document.getElementById("error-message").error.message);
  }
};

 // Get Stripe publishable key to initialize Stripe.js
fetch("/setup")
  .then(function(result) {
    return result.json();
  })
  .then(function(json) {
    var publishableKey = json.publishableKey;
    var basicPriceId = json.basicPrice;

    var stripe = Stripe(publishableKey);
    // Setup event handler to create a Checkout Session when button is clicked
    var basicPlanButton = document.getElementById("activate-premium-plan-btn");

    if ( basicPlanButton ){
      basicPlanButton.addEventListener("click", function(evt) {
        createCheckoutSession(basicPriceId).then(function(data) {
          // Call Stripe.js method to redirect to the new Checkout page
          stripe
            .redirectToCheckout({
              sessionId: data.sessionId
            })
            .then(handleResult);
        });
      });      
    }
  });
  

// Cancel subscription link
var form = document.getElementById("cancel-subscription-form");
if (form){
  document.getElementById("cancel-subscription-link").addEventListener("click", function () {
    form.submit();
  });  
}

// Use backup image with Favicon does not load
document.addEventListener("DOMContentLoaded", function(event) {
   document.querySelectorAll('img').forEach(function(img){
  	img.onerror = function(){
      this.onerror=null;
      console.log(this.getAttribute('data-backup'));
      this.src = this.getAttribute('data-backup');
    };
   })
});


// Get user timezone
user_timezone = new Date().toString().match(/GMT([^ ]+)/)[1];
document.cookie = `user_timezone=${user_timezone.slice(0, 3)}:${user_timezone.slice(3,5)}`;