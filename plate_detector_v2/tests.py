from pathlib import Path
from ultralytics import YOLO

script_dir = Path(__file__).resolve().parent

# 1. Cargar el modelo con los pesos aprendidos (best.pt)
model_path = script_dir / "yolo11_placas" / "exp_nano" / "weights" / "best.pt"
model = YOLO(model_path)

# 2. Seleccionar una imagen de prueba
imagen_prueba = script_dir / "dataset" / "images" / "A_001.jpg"

# 3. Realizar predicción con umbral de confianza del 50% (conf=0.5)
results = model.predict(
  source=str(imagen_prueba),
  conf=0.5,
  save=True,          # Guarda la imagen con la caja delimitadora y etiqueta dibujada
  project="pruebas",
  name="resultado"
)

print("Predicción completada. Revisa la imagen anotada en: pruebas/resultado/")