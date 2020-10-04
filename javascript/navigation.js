// Navigation
document.addEventListener('DOMContentLoaded', () => {
  const navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);

  // Check if there are any navbar burgers
  if (navbarBurgers.length > 0) {

    // Add a click event on each of them
    navbarBurgers.forEach( burger => {
      
      // burger.addEventListener('blur', () => {
      //
      //   // Get the target from the "data-target" attribute
      //   const nav = document.getElementById( burger.dataset.target );
      //
      //   // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
      //   burger.classList.toggle('is-active');
      //   nav.classList.toggle('is-active');
      //   console.log('blur');
      //
      // });
      //

      burger.addEventListener('click', () => {

        // Get the target from the "data-target" attribute
        const nav = document.getElementById( burger.dataset.target );

        // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
        burger.classList.toggle('is-active');
        nav.classList.toggle('is-active');
        nav.focus();
        
      });
    }); 
  }
});