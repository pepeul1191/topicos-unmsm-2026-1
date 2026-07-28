import torch
from pathlib import Path
from ultralytics import YOLO

def seleccionar_dispositivo():
  """Permite seleccionar mediante el teclado el hardware para el entrenamiento."""
  cuda_disponible = torch.cuda.is_available()
  
  print("\n" + "="*45)
  print(" SELECCIÓN DE HARDWARE PARA ENTRENAMIENTO")
  print("="*45)
  
  if cuda_disponible:
    nombre_gpu = torch.cuda.get_device_name(0)
    print(f"  [1] GPU: {nombre_gpu}")
  else:
    print("  [1] GPU: (No detectada en PyTorch)")
    
  print("  [2] CPU")
  print("="*45)

  mimodulo = input("Selecciona una opción (1 o 2): ").strip()

  if mimodulo == "1":
    if not cuda_disponible:
      print("\n⚠️ Advertencia: PyTorch no detecta una GPU CUDA activa.")
      print("Se intentará forzar 'device=0', pero puede fallar si no tienes los drivers/PyTorch CUDA instalados.\n")
    else:
      print("\n🚀 Dispositivo seleccionado: GPU (device=0)\n")
    return "0"
  else:
    print("\n💻 Dispositivo seleccionado: CPU (device='cpu')\n")
    return "cpu"

def entrenar_yolo11_nano():
  # Raíz del proyecto (/home/pepe/Documentos/topicos/plate_detector_v2)
  root_dir = Path(__file__).resolve().parent

  # Ruta exacta al dataset.yaml dentro de scripts/dataset/
  yaml_path = root_dir / "scripts" / "dataset" / "dataset.yaml"

  print(f"Cargando configuración desde: {yaml_path}")

  if not yaml_path.exists():
    print(f"Error: No se encontró el archivo en {yaml_path}")
    return

  # 1. Seleccionar dispositivo por teclado
  dispositivo = seleccionar_dispositivo()

  # 2. Cargar el yolo11n.pt localizado en la raíz
  model = YOLO(root_dir / "yolo11n.pt")

  # 3. Iniciar el entrenamiento
  results = model.train(
    data=str(yaml_path),
    epochs=50,
    imgsz=640,
    batch=16,
    device=dispositivo,      # '0' para GPU o 'cpu' para CPU
    project="yolo11_placas",
    name="exp_nano",
    save=True,
    plots=True
  )

  print("\n¡Entrenamiento completado exitosamente!")

if __name__ == "__main__":
  entrenar_yolo11_nano()