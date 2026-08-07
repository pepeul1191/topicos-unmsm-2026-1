import torch
import os
import pandas as pd
from ultralytics import YOLO


def seleccionar_dispositivo():
    """Selecciona GPU o CPU."""

    cuda_disponible = torch.cuda.is_available()

    print("\n" + "=" * 45)
    print(" SELECCIÓN DE HARDWARE PARA VALIDACIÓN")
    print("=" * 45)

    if cuda_disponible:
        print(f"  [1] GPU: {torch.cuda.get_device_name(0)}")
    else:
        print("  [1] GPU: (No disponible)")

    print("  [2] CPU")
    print("=" * 45)

    opcion = input("Selecciona una opción (1 o 2): ").strip()

    if opcion == "1" and cuda_disponible:
        print("\n🚀 Validando con GPU\n")
        return 0

    print("\n💻 Validando con CPU\n")
    return "cpu"


def evaluar_modelos():

    root_dir = os.path.dirname(os.path.abspath(__file__))

    # Dataset OCR de 37 clases
    yaml_path = os.path.join(
        root_dir,
        "scripts",
        "dataset",
        "dataset.yaml"
    )

    models_dir = os.path.join(root_dir, "models")

    modelos = [
        "best_upeu_yolo12_100ep.pt",
        "modelo_v2.pt",
        "modelo_v3.pt",
        "yolov8n.pt"
    ]

    print("\n===== Información PyTorch =====")
    print("Versión:", torch.__version__)
    print("CUDA compilado:", torch.version.cuda)
    print("CUDA disponible:", torch.cuda.is_available())
    print("Número GPUs:", torch.cuda.device_count())

    if torch.cuda.is_available():
        print("GPU:", torch.cuda.get_device_name(0))

    print("=" * 35)

    dispositivo = seleccionar_dispositivo()

    resultados = []

    for nombre in modelos:

        ruta_modelo = os.path.join(models_dir, nombre)

        print("\n" + "="*50)
        print("Modelo:", nombre)

        model = YOLO(ruta_modelo)

        num_clases = len(model.names)

        print("Clases del modelo:", num_clases)

        # Solo OCR 37 clases
        if num_clases != 37:
            print("⏭ Modelo omitido (clases incompatibles)")
            continue

        print("🚀 Ejecutando validación...")

        metrics = model.val(
            data=yaml_path,
            imgsz=640,
            batch=16,
            device=dispositivo,
            plots=True,
            verbose=False
        )

        precision = metrics.box.mp
        recall = metrics.box.mr
        map50 = metrics.box.map50
        map95 = metrics.box.map

        f1 = (
            2 * precision * recall /
            (precision + recall)
        )

        resultados.append({
            "Modelo": nombre,
            "Precision": precision,
            "Recall": recall,
            "F1": f1,
            "mAP50": map50,
            "mAP50-95": map95
        })


    df = pd.DataFrame(resultados)

    print("\n\n===== RESULTADOS =====")
    print(df)

    df.to_csv(
        "comparacion_modelos_gpu.csv",
        index=False
    )

    print("\nArchivo generado: comparacion_modelos_gpu.csv")


if __name__ == "__main__":
    evaluar_modelos()