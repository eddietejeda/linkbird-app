// Use backup image with Favicon does not load
document.addEventListener("DOMContentLoaded", function(event) {
   document.querySelectorAll('img').forEach(function(img){
  	img.onerror = function(){
      this.onerror=null;
      console.log(this.getAttribute('data-backup'));
      this.src = this.getAttribute('data-backup');
    };
   })


   document.querySelectorAll('.hide-alert').forEach(function(btn){
     btn.addEventListener("click", function (e) {
       e.target.parentElement.style.display = 'none';
     });
   })
});
