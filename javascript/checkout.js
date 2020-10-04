// Get Stripe publishable key to initialize Stripe.js
document.addEventListener("DOMContentLoaded", function(event) {
  document.querySelectorAll('.activate-premium-plan-btn').forEach(function(subcriptionButton){
    fetch("/checkout/setup").then(function(result) {
        return result.json();
      })
      .then(function(json) {
        var publishableKey = json.publishableKey;
        var subcriptionPriceId = json.subcriptionPriceId;

        var stripe = Stripe(publishableKey);
        // Setup event handler to create a Checkout Session when button is clicked
        subcriptionButton.addEventListener("click", function(evt) {
          evt.target.innerHTML = "Loading..."
          evt.target.className = "button is-light"
          
          createCheckoutSession(subcriptionPriceId).then(function(data) {
            // Call Stripe.js method to redirect to the new Checkout page
            stripe.redirectToCheckout({
              sessionId: data.sessionId
            }).then(handleResult);
          });
        });
      });
  });
});



// Cancel subscription link
document.querySelectorAll('.cancel-subscription-link').forEach(function(link){
  link.addEventListener("click", function () {
    document.getElementById('cancel-subscription-form').submit();
  }); 
});


// Create a Checkout Session with the selected plan ID
var createCheckoutSession = function(subcriptionPriceId) {
  return fetch("/checkout/session", {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      subcriptionPriceId: subcriptionPriceId
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