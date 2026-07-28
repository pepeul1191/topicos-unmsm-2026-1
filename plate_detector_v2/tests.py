import cv2
import torch
from pathlib import Path
from ultralytics import YOLO

def probar_deteccion_placa():
  # Obtiene la raíz del proyecto automáticamente sin importar la ruta absoluta
  root_dir = Path(__file__).resolve().parent
  model_path = root_dir / "runs" / "exp_nano-5" / "weights" / "best.pt"

  if not model_path.exists():
    print(f"Error: No se encontró el modelo en: {model_path}")
    print("Asegúrate de haber copiado la carpeta 'runs/' dentro de 'plate_detector_v2/'.")
    return

  # Cargar el modelo entrenado
  model = YOLO(model_path)

  # Seleccionar dispositivo (GPU si está disponible, de lo contrario CPU)
  dispositivo = "0" if torch.cuda.is_available() else "cpu"
  print(f"Cargando modelo usando: {dispositivo}")

  # Ruta a la imagen de prueba dentro de dataset/images
  imagen_path = root_dir / "scripts" / "dataset" / "images" / "Z_200.jpg"

  if not imagen_path.exists():
    print(f"Error: No existe la imagen de prueba en {imagen_path}")
    return

  # Realizar la inferencia
  results = model.predict(source=str(imagen_path), conf=0.5, device=dispositivo)

  # Extraer y ordenar los caracteres de izquierda a derecha (coordenada x_1)
  detecciones = []
  for result in results:
    for box in result.boxes:
      # Coordenada x1 (extremo izquierdo de la caja delimitadora)
      x1 = box.xyxy[0][0].item()
      clase_id = int(box.cls[0].item())
      nombre_clase = result.names[clase_id]
      detecciones.append((x1, nombre_clase))

  # Ordenar de menor a mayor coordenada x
  detecciones.sort(key=lambda item: item[0])

  # Reconstruir el texto completo
  texto_placa = "".join([clase for x, clase in detecciones])

  print("\n" + "="*40)
  print(f" TEXTO DETECTADO EN LA PLACA: {texto_placa}")
  print("="*40)

if __name__ == "__main__":
  probar_deteccion_placa()