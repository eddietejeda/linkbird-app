// Pull down to refresh content
// https://dev.to/vijitail/pull-to-refresh-animation-with-vanilla-javascript-17oc
const pStart = { x: 0, y: 0 };
const pCurrent = { x: 0, y: 0 };
const loading = document.querySelector("body > .loading-container");
var isLoading = false; // Yeah, yeah. Using a global.

if (loading){
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
    isLoading=false;
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
      if (changeY > 100 && isLoading == false) {
        loading.style.display = 'flex';
        isLoading = true;
        fetch('/refresh');
        setTimeout(() => {
          loading.style.display = 'none';
          window.location = '/';
        }, 3000);
      }
    }
  }

  document.addEventListener("touchstart", e => swipeStart(e), false);
  document.addEventListener("touchmove", e => swipe(e), false);
}