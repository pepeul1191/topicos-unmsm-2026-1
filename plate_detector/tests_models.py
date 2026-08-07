from pathlib import Path
import torch
import pandas as pd
from ultralytics import YOLO


# =====================================================
# RUTAS
# =====================================================

ROOT = Path(__file__).resolve().parent

MODELOS = [
    ROOT / "models" / "modelo_v2.pt",
    ROOT / "models" / "modelo_v3.pt"
]

IMG_DIR = ROOT / "synthetic_plates" / "images"
RESULT_DIR = ROOT / "detalle_models"

# Crear carpeta de resultados (si no existe)
RESULT_DIR.mkdir(parents=True, exist_ok=True)


# =====================================================
# GPU
# =====================================================

if torch.cuda.is_available():
    DEVICE = 0
    print("GPU disponible:", torch.cuda.get_device_name(0))
else:
    DEVICE = "cpu"
    print("GPU no disponible, usando CPU")


# =====================================================
# GROUND TRUTH
# =====================================================

def obtener_real(nombre):
    # Ejemplo: IDW-304.jpg -> IDW-304
    return Path(nombre).stem


# =====================================================
# DECODIFICAR DETECCIONES (usando model.names)
# =====================================================

def obtener_texto(resultado, modelo):
    """
    Extrae el texto de las detecciones ordenadas de izquierda a derecha.
    Usa el mapeo de clases que el modelo tiene internamente.
    """
    # Obtener el diccionario de nombres de clases (ej: {0: '0', 1: '1', ..., 10: 'A', ...})
    nombres = modelo.names

    caracteres = []

    for box in resultado.boxes:
        confianza = float(box.conf[0])
        # Umbral de confianza (ajústalo según necesites)
        if confianza < 0.25:   # <--- Cambia este valor si quieres más o menos sensibilidad
            continue

        clase = int(box.cls[0])
        # El nombre de la clase ya es el carácter esperado (ej. 'A', '5', '-')
        caracter = nombres[clase]

        # Coordenadas para ordenar horizontalmente
        x1 = float(box.xyxy[0][0])
        x2 = float(box.xyxy[0][2])
        centro_x = (x1 + x2) / 2

        caracteres.append((centro_x, caracter, confianza))

    # Ordenar por posición X (izquierda a derecha)
    caracteres.sort(key=lambda x: x[0])

    # Construir el texto final
    texto = "".join(c[1] for c in caracteres)
    return texto, caracteres


# =====================================================
# COMPARAR CARACTERES
# =====================================================

def comparar(real, pred):
    correctos = 0
    for i in range(min(len(real), len(pred))):
        if real[i] == pred[i]:
            correctos += 1
    return correctos


# =====================================================
# EVALUAR MODELO
# =====================================================

def evaluar_modelo(modelo_path):
    print("\n")
    print("=" * 60)
    print("Evaluando:", modelo_path)
    print("=" * 60)

    modelo = YOLO(str(modelo_path))

    # Mostrar el mapeo de clases para depuración
    print("Mapeo de clases del modelo:")
    print(modelo.names)
    print("-" * 40)

    imagenes = list(IMG_DIR.glob("*.jpg"))
    total = len(imagenes)

    correctas = 0
    caracteres_ok = 0
    caracteres_total = 0
    detalle = []

    for i, img in enumerate(imagenes):
        resultado = modelo.predict(
            source=str(img),
            device=DEVICE,
            conf=0.25,          # Umbral de confianza (puedes cambiarlo)
            verbose=False
        )[0]

        pred, detecciones = obtener_texto(resultado, modelo)
        real = obtener_real(img.name)

        ok = comparar(real, pred)
        caracteres_ok += ok
        caracteres_total += len(real)

        if pred == real:
            correctas += 1

        detalle.append({
            "imagen": img.name,
            "real": real,
            "prediccion": pred,
            "correcta": pred == real,
            "caracteres_correctos": ok
        })

        if (i + 1) % 50 == 0:
            print(f"{i+1}/{total}")

    accuracy = (correctas / total) * 100
    accuracy_char = (caracteres_ok / caracteres_total) * 100 if caracteres_total > 0 else 0

    print("\nRESULTADO")
    print(f"Correctas: {correctas}/{total}")
    print(f"Accuracy lectura: {accuracy:.2f}%")
    print(f"Accuracy caracteres: {accuracy_char:.2f}%")

    # Guardar CSV
    archivo = RESULT_DIR / f"{modelo_path.stem}_resultado.csv"
    archivo.parent.mkdir(parents=True, exist_ok=True)
    pd.DataFrame(detalle).to_csv(archivo, index=False)
    print("Archivo generado:", archivo)


# =====================================================
# PRUEBA INDIVIDUAL (para depuración)
# =====================================================

def probar_imagen(modelo_path, nombre_imagen):
    """
    Prueba una sola imagen y muestra las detecciones con detalle.
    """
    modelo = YOLO(str(modelo_path))
    imagen = IMG_DIR / nombre_imagen

    if not imagen.exists():
        print(f"Error: la imagen {imagen} no existe.")
        return

    resultado = modelo.predict(
        source=str(imagen),
        device=DEVICE,
        conf=0.25,
        save=True          # Guarda la imagen con las cajas dibujadas
    )[0]

    texto, cajas = obtener_texto(resultado, modelo)

    print("\n" + "=" * 50)
    print("PRUEBA INDIVIDUAL")
    print("=" * 50)
    print(f"Imagen: {imagen.name}")
    print(f"Predicción: {texto}")
    print("\nDetalle de caracteres detectados (ordenados de izquierda a derecha):")
    for i, (cx, car, conf) in enumerate(cajas):
        print(f"  {i+1}: '{car}'  (confianza: {conf:.3f}, posición X: {cx:.1f})")
    print("=" * 50)


# =====================================================
# MAIN
# =====================================================

if __name__ == "__main__":
    # Evaluar todos los modelos
    for modelo in MODELOS:
        evaluar_modelo(modelo)

    # Opcional: probar una imagen concreta (descomenta y ajusta el nombre)
    # probar_imagen(MODELOS[0], "IDW-304.jpg")