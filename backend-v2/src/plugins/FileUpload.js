export class FileUpload {
  constructor(options = {}) {
    // Configurable DOM element IDs
    this.containerId = options.containerId || "fileUploadContainer";
    this.fileInputId = options.fileInputId || "imageFile";
    this.triggerButtonId = options.triggerButtonId || "triggerFileButton"; // Botón que dispara el file input
    this.uploadButtonId = options.uploadButtonId || "uploadButton";
    this.viewButtonId = options.viewButtonId || "viewImageButton";
    this.errorMessageId = options.errorMessageId || "errorMessage";
    this.successMessageId = options.successMessageId || "successMessage";
    this.helpTextId = options.helpTextId || "helpText";
    this.labelElementId = options.labelElementId || null;
    this.fileNameDisplayId = options.fileNameDisplayId || "fileNameDisplay"; // Para mostrar el nombre del archivo
    
    // Component configuration
    this.label = options.label || "Seleccionar imagen";
    this.acceptedFormats = options.acceptedFormats || ["jpg", "jpeg", "png"];
    this.maxSizeMB = options.maxSizeMB || 2;
    this.baseURL = options.baseURL || "";
    this.url = this.baseURL + "/" + options.url || "/api/upload";
    this.fileKey = options.fileKey || "file";
    this.extraParams = options.extraParams || {};
    this.jwt = options.jwt || "";
    this.triggerButtonText = options.triggerButtonText || "Seleccionar archivo";
    this.triggerButtonIcon = options.triggerButtonIcon || "fa-folder-open";
    
    // Callbacks
    this.onSuccess = options.onSuccess || ((response) => console.log("Upload success:", response));
    this.onError = options.onError || ((error) => console.error("Upload error:", error));
    this.onViewClick = options.onViewClick || (() => {
      console.log("View button clicked");
    });
    
    this.file = null;
    this.isLoading = false;
    
    this.initElements();
    this.setupEventListeners();
    this.updateUI();
  }
  
  initElements() {
    // Get all DOM elements by configurable IDs
    this.container = document.getElementById(this.containerId);
    this.fileInput = document.getElementById(this.fileInputId);
    this.triggerButton = document.getElementById(this.triggerButtonId);
    this.uploadButton = document.getElementById(this.uploadButtonId);
    this.viewButton = document.getElementById(this.viewButtonId);
    this.errorMessage = document.getElementById(this.errorMessageId);
    this.successMessage = document.getElementById(this.successMessageId);
    this.helpText = document.getElementById(this.helpTextId);
    this.fileNameDisplay = document.getElementById(this.fileNameDisplayId);
    
    // Get label element (either by ID or as first label in container)
    this.labelElement = this.labelElementId 
      ? document.getElementById(this.labelElementId)
      : this.container.querySelector('label');
    
    // Update initial values
    if (this.labelElement) {
      this.labelElement.textContent = this.label;
    }
    
    // Configurar input file (oculto)
    this.fileInput.style.display = 'none';
    this.fileInput.accept = this.acceptedFormats.map(f => `.${f}`).join(',');
    
    // Configurar texto de ayuda
    if (this.helpText) {
      this.helpText.textContent = 
        `Formatos aceptados: ${this.acceptedFormats.join(", ").toUpperCase()} (Máx. ${this.maxSizeMB}MB)`;
    }
    
    // Configurar botón trigger si no tiene icono/texto personalizado
    if (this.triggerButton && this.triggerButtonText) {
      const existingIcon = this.triggerButton.querySelector('i');
      if (!existingIcon && this.triggerButtonIcon) {
        this.triggerButton.innerHTML = `<i class="fa ${this.triggerButtonIcon} me-2"></i>${this.triggerButtonText}`;
      } else if (this.triggerButton.textContent.trim() === '') {
        this.triggerButton.textContent = this.triggerButtonText;
      }
    }
  }
  
  setupEventListeners() {
    // Trigger button abre el selector de archivos
    if (this.triggerButton) {
      this.triggerButton.addEventListener('click', () => {
        this.fileInput.click();
      });
    }
    
    this.fileInput.addEventListener('change', this.handleFileChange.bind(this));
    this.uploadButton.addEventListener('click', this.uploadFile.bind(this));
    this.viewButton.addEventListener('click', () => {
      this.onViewClick(this.file, document.getElementById(this.fileNameDisplayId)?.dataset.imageUrl);
    });
  }
  
  handleFileChange(event) {
    const selectedFile = event.target.files[0];
    if (!selectedFile) return;

    // Validate format
    const fileExt = selectedFile.name.split('.').pop().toLowerCase();
    if (!this.acceptedFormats.includes(fileExt)) {
      this.showError(`Formato no válido. Use: ${this.acceptedFormats.join(", ").toUpperCase()}`);
      this.fileInput.value = ''; // Limpiar input
      return;
    }

    // Validate size
    if (selectedFile.size > this.maxSizeMB * 1024 * 1024) {
      this.showError(`El archivo excede el tamaño máximo de ${this.maxSizeMB}MB`);
      this.fileInput.value = ''; // Limpiar input
      return;
    }

    this.clearMessages();
    this.file = selectedFile;
    
    // Mostrar nombre del archivo seleccionado
    if (this.fileNameDisplay) {
      this.fileNameDisplay.textContent = `📎 ${selectedFile.name}`;
      this.fileNameDisplay.style.color = '#28a745';
      this.fileNameDisplay.dataset.imageUrl = '';
    }
    
    this.updateUI();
  }
  
  async uploadFile() {
    if (!this.file) {
      this.showError("Por favor seleccione un archivo");
      return;
    }

    this.isLoading = true;
    this.clearMessages();
    this.updateUI();

    const formData = new FormData();
    formData.append(this.fileKey, this.file);

    // Add extra parameters
    Object.keys(this.extraParams).forEach(key => {
      formData.append(key, this.extraParams[key]);
    });

    try {
      const headers = {};
      if (this.jwt) {
        headers["Authorization"] = `Bearer ${this.jwt}`;
      }
      
      const response = await fetch(this.url, {
        method: "POST",
        headers: headers,
        body: formData, 
        mode: "cors",
        credentials: "include"
      });

      const data = await response.json();
      console.log(data);
      
      if (!response.ok) {
        throw new Error(data.message || "Error al subir el archivo");
      }

      this.showSuccess("Archivo subido correctamente");
      
      // Guardar URL en el display si existe
      if (this.fileNameDisplay && data.image_url) {
        this.fileNameDisplay.dataset.imageUrl = data.image_url;
      }
      
      this.onSuccess(data);
    } catch (error) {
      this.showError(error.message);
      this.onError(error);
    } finally {
      this.isLoading = false;
      this.updateUI();
    }
  }
  
  showError(message) {
    if (this.errorMessage) {
      this.errorMessage.textContent = message;
      this.errorMessage.style.color = '#dc3545';
    }
    if (this.successMessage) {
      this.successMessage.textContent = "";
    }
  }
  
  showSuccess(message) {
    if (this.successMessage) {
      this.successMessage.textContent = message;
      this.successMessage.style.color = '#28a745';
    }
    if (this.errorMessage) {
      this.errorMessage.textContent = "";
    }
  }
  
  clearMessages() {
    if (this.errorMessage) this.errorMessage.textContent = "";
    if (this.successMessage) this.successMessage.textContent = "";
  }
  
  updateUI() {
    // Update buttons state
    if (this.uploadButton) {
      this.uploadButton.disabled = this.isLoading || !this.file;
    }
    if (this.viewButton) {
      this.viewButton.disabled = this.isLoading || (!this.file && !this.fileNameDisplay?.dataset.imageUrl);
    }
    if (this.triggerButton) {
      this.triggerButton.disabled = this.isLoading;
    }
    
    // Update upload button text and icon
    if (this.uploadButton) {
      const uploadIcon = this.uploadButton.querySelector('i');
      const uploadText = this.uploadButton.childNodes[2];
      
      if (this.isLoading) {
        if (uploadIcon) uploadIcon.className = "fa fa-spinner spinner";
        if (uploadText) uploadText.nodeValue = " Subiendo...";
      } else {
        if (uploadIcon) uploadIcon.className = "fa fa-cloud-upload";
        if (uploadText) uploadText.nodeValue = " Subir";
      }
    }
    
    // Update input state
    if (this.fileInput) {
      this.fileInput.disabled = this.isLoading;
    }
  }
  
  // Método público para limpiar el archivo seleccionado
  clearFile() {
    this.file = null;
    this.fileInput.value = '';
    if (this.fileNameDisplay) {
      this.fileNameDisplay.textContent = '';
      this.fileNameDisplay.dataset.imageUrl = '';
    }
    this.clearMessages();
    this.updateUI();
  }
  
  // Método público para establecer URL de imagen existente
  setExistingImageUrl(url) {
    if (this.fileNameDisplay) {
      this.fileNameDisplay.dataset.imageUrl = url;
      this.fileNameDisplay.textContent = `🖼️ Imagen existente`;
      this.fileNameDisplay.style.color = '#17a2b8';
    }
    this.updateUI();
  }
}