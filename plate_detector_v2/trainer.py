import torch
from pathlib import Path
from ultralytics import YOLO


def seleccionar_dispositivo():
    """Permite seleccionar mediante el teclado el hardware para el entrenamiento."""

    cuda_disponible = torch.cuda.is_available()

    print("\n" + "=" * 45)
    print(" SELECCIÓN DE HARDWARE PARA ENTRENAMIENTO")
    print("=" * 45)

    if cuda_disponible:
        print(f"  [1] GPU: {torch.cuda.get_device_name(0)}")
    else:
        print("  [1] GPU: (No disponible)")

    print("  [2] CPU")
    print("=" * 45)

    opcion = input("Selecciona una opción (1 o 2): ").strip()

    # Si el usuario quiere GPU
    if opcion == "1":
        if cuda_disponible:
            print("\n🚀 Entrenando con GPU\n")
            return 0  # también podría ser "0"
        else:
            print("\n⚠️ CUDA no está disponible en PyTorch.")
            print("Se utilizará CPU automáticamente.\n")
            return "cpu"

    # Cualquier otra opción usa CPU
    print("\n💻 Entrenando con CPU\n")
    return "cpu"


def entrenar_yolo11_nano():

    # Directorio raíz del proyecto
    root_dir = Path(__file__).resolve().parent

    # Dataset
    yaml_path = root_dir / "scripts" / "dataset" / "dataset.yaml"

    print(f"Cargando configuración desde: {yaml_path}")

    if not yaml_path.exists():
        print(f"❌ No se encontró el archivo:\n{yaml_path}")
        return

    # Mostrar información de PyTorch
    print("\n===== Información de PyTorch =====")
    print("Versión:", torch.__version__)
    print("CUDA compilado:", torch.version.cuda)
    print("CUDA disponible:", torch.cuda.is_available())
    print("Número de GPUs:", torch.cuda.device_count())

    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))

    print("=" * 35)

    # Seleccionar dispositivo
    dispositivo = seleccionar_dispositivo()

    # Cargar modelo
    model = YOLO(str(root_dir / "yolo11n.pt"))

    # Entrenamiento
    results = model.train(
        data=str(yaml_path),
        epochs=50,
        imgsz=640,
        batch=16,
        device=dispositivo,
        project="yolo11_placas",
        name="exp_nano",
        save=True,
        plots=True,
    )

    print("\n✅ Entrenamiento finalizado correctamente.")


if __name__ == "__main__":
    entrenar_yolo11_nano()
