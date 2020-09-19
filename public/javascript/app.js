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

/* Get your Stripe publishable key to initialize Stripe.js */
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
  
  
var form = document.getElementById("cancel-subscription-form");

if (form){
  document.getElementById("cancel-subscription-link").addEventListener("click", function () {
    form.submit();
  });  
}


document.addEventListener("DOMContentLoaded", function(event) {
   document.querySelectorAll('img').forEach(function(img){
  	img.onerror = function(){
      this.onerror=null;
      console.log(this.getAttribute('data-backup'));
      this.src = this.getAttribute('data-backup');
    };
   })
});



// new Date().toLocaleDateString(undefined, { timeZoneName: 'short' })
user_timezone = new Date().toString().match(/GMT([^ ]+)/)[1];
document.cookie = `user_timezone=${user_timezone.slice(0, 3)}:${user_timezone.slice(3,5)}`;