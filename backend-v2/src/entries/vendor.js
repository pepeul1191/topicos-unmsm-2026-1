import 'bootstrap/dist/css/bootstrap.min.css';
import 'font-awesome/css/font-awesome.min.css';
import 'bootstrap/dist/js/bootstrap.min.js';
import '../stylesheets/styles.css';

document.addEventListener('DOMContentLoaded', function() {
  // Cerrar alerts al hacer click en el botón
  const closeButtons = document.querySelectorAll('.alert .btn-close');
  
  closeButtons.forEach(button => {
    button.addEventListener('click', function() {
      const alert = this.closest('.alert');
      alert.style.opacity = '0';
      setTimeout(() => {
        alert.remove();
      }, 200);
    });
  });

  // Auto-cerrar alerts después de 5 segundos (opcional)
  const alerts = document.querySelectorAll('.alert');
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert.parentNode) {
        alert.style.opacity = '0';
        setTimeout(() => {
          if (alert.parentNode) {
            alert.remove();
          }
        }, 600);
      }
    }, 5000);
  });
});