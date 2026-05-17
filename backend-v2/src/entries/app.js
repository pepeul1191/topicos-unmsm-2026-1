import '../stylesheets/styles.css'; 
import '../stylesheets/dashboard.css'; 
import { AutoComplete } from '../plugins/AutoComplete.js';
import '../plugins/AutoComplete.css';
import { FileUpload } from '../plugins/FileUpload.js';
import '../plugins/FileUpload.css';

window.AutoComplete = AutoComplete;
window.FileUpload = FileUpload;

document.addEventListener('DOMContentLoaded', function() {
  const sidebarToggle = document.getElementById('sidebarToggle');
  const sidebar = document.querySelector('.sidebar');
  
  let isCollapsed = localStorage.getItem('sidebarCollapsed') === 'true';
  
  function updateSidebarState() {
    if (window.innerWidth <= 992) {
      sidebar.classList.add('collapsed');
    } else {
      sidebar.classList.toggle('collapsed', isCollapsed);
    }
  }
  
  updateSidebarState();
  
  sidebarToggle.addEventListener('click', function() {
    if (window.innerWidth <= 992) {
      sidebar.classList.toggle('collapsed');
    } else {
      isCollapsed = !isCollapsed;
      localStorage.setItem('sidebarCollapsed', isCollapsed);
      sidebar.classList.toggle('collapsed');
    }
  });
  
  document.querySelectorAll('.sidebar .nav-link').forEach(link => {
    link.addEventListener('click', function() {
      if (window.innerWidth <= 992) {
        sidebar.classList.add('collapsed');
      }
    });
  });
  
  window.addEventListener('resize', function() {
    updateSidebarState();
  });
});