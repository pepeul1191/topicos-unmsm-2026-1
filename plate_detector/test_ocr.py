from pathlib import Path
import torch
import pandas as pd
import cv2
import easyocr
from ultralytics import YOLO

# =====================================================
# RUTAS Y CONFIGURACIÓN
# =====================================================

ROOT = Path(__file__).resolve().parent

MODELOS = [
    ROOT / "models" / "modelo_v2.pt",
    ROOT / "models" / "modelo_v3.pt"
]

IMG_DIR = ROOT / "synthetic_plates" / "images"
RESULT_DIR = ROOT / "detalle_comparativo"
RESULT_DIR.mkdir(parents=True, exist_ok=True)

# =====================================================
# GPU
# =====================================================

if torch.cuda.is_available():
    DEVICE = 0
    OCR_DEVICE = "cuda"
    print(f"GPU disponible: {torch.cuda.get_device_name(0)}")
else:
    DEVICE = "cpu"
    OCR_DEVICE = "cpu"
    print("GPU no disponible, usando CPU")

# =====================================================
# INICIALIZAR OCR
# =====================================================

reader = easyocr.Reader(['en'], gpu=(OCR_DEVICE == "cuda"))

# =====================================================
# FUNCIONES AUXILIARES
# =====================================================

def obtener_real(nombre):
    """Extrae el texto real del nombre del archivo (sin extensión)."""
    return Path(nombre).stem

def limpiar_texto_ocr(texto):
    """Limpia el texto devuelto por OCR: mayúsculas, solo alfanumérico y guion."""
    texto = texto.upper()
    texto = ''.join(c for c in texto if c.isalnum() or c == '-')
    return texto

def aplicar_ocr(imagen_path):
    """Aplica EasyOCR a la imagen y devuelve el texto limpio."""
    img = cv2.imread(str(imagen_path))
    if img is None:
        return ""
    resultados = reader.readtext(img, detail=0)
    texto_completo = ' '.join(resultados)
    return limpiar_texto_ocr(texto_completo)

def comparar(real, pred):
    """Compara dos strings carácter a carácter (por posición)."""
    correctos = 0
    for i in range(min(len(real), len(pred))):
        if real[i] == pred[i]:
            correctos += 1
    return correctos

# =====================================================
# DECODIFICACIÓN DE YOLO (usando model.names)
# =====================================================

def obtener_texto_yolo(resultado, modelo):
    """
    Extrae el texto de las detecciones de YOLO ordenadas de izquierda a derecha.
    Usa el mapeo de clases interno del modelo.
    """
    nombres = modelo.names
    caracteres = []

    for box in resultado.boxes:
        confianza = float(box.conf[0])
        if confianza < 0.25:      # Umbral ajustable
            continue
        clase = int(box.cls[0])
        caracter = nombres[clase]

        x1 = float(box.xyxy[0][0])
        x2 = float(box.xyxy[0][2])
        centro_x = (x1 + x2) / 2

        caracteres.append((centro_x, caracter, confianza))

    caracteres.sort(key=lambda x: x[0])
    texto = "".join(c[1] for c in caracteres)
    return texto

# =====================================================
# EVALUACIÓN DE UN MODELO YOLO
# =====================================================

def evaluar_modelo_yolo(modelo_path):
    modelo = YOLO(str(modelo_path))
    imagenes = list(IMG_DIR.glob("*.jpg"))
    total = len(imagenes)

    resultados = []
    for i, img_path in enumerate(imagenes):
        real = obtener_real(img_path.name)

        # Predicción YOLO
        resultado = modelo.predict(
            source=str(img_path),
            device=DEVICE,
            conf=0.25,
            verbose=False
        )[0]
        pred_yolo = obtener_texto_yolo(resultado, modelo)

        resultados.append({
            "imagen": img_path.name,
            "real": real,
            "pred_yolo": pred_yolo,
        })

        if (i + 1) % 50 == 0:
            print(f"YOLO {modelo_path.stem}: {i+1}/{total}")

    return pd.DataFrame(resultados)

# =====================================================
# EVALUACIÓN DE OCR
# =====================================================

def evaluar_ocr():
    imagenes = list(IMG_DIR.glob("*.jpg"))
    total = len(imagenes)

    resultados = []
    for i, img_path in enumerate(imagenes):
        real = obtener_real(img_path.name)
        pred_ocr = aplicar_ocr(img_path)

        resultados.append({
            "imagen": img_path.name,
            "real": real,
            "pred_ocr": pred_ocr,
        })

        if (i + 1) % 50 == 0:
            print(f"OCR: {i+1}/{total}")

    return pd.DataFrame(resultados)

# =====================================================
# CÁLCULO DE MÉTRICAS Y GUARDADO
# =====================================================

def calcular_metricas(df, col_pred):
    """
    Calcula precisión por placa y por carácter para una columna de predicciones.
    """
    correctas_placa = 0
    caracteres_acertados = 0
    caracteres_totales = 0

    for _, row in df.iterrows():
        real = row["real"]
        pred = row[col_pred]
        if pred == real:
            correctas_placa += 1
        caracteres_acertados += comparar(real, pred)
        caracteres_totales += len(real)

    acc_placa = (correctas_placa / len(df)) * 100
    acc_char = (caracteres_acertados / caracteres_totales) * 100 if caracteres_totales > 0 else 0
    return acc_placa, acc_char

# =====================================================
# MAIN
# =====================================================

if __name__ == "__main__":
    print("=" * 60)
    print("EVALUACIÓN COMPARATIVA: YOLO vs OCR")
    print("=" * 60)

    # --- 1. Evaluar OCR ---
    print("\n>>> Evaluando OCR...")
    df_ocr = evaluar_ocr()
    acc_placa_ocr, acc_char_ocr = calcular_metricas(df_ocr, "pred_ocr")

    # --- 2. Evaluar cada modelo YOLO ---
    resultados_yolo = {}
    for modelo_path in MODELOS:
        print(f"\n>>> Evaluando YOLO: {modelo_path.stem}...")
        df_yolo = evaluar_modelo_yolo(modelo_path)
        acc_placa, acc_char = calcular_metricas(df_yolo, "pred_yolo")
        resultados_yolo[modelo_path.stem] = {
            "df": df_yolo,
            "acc_placa": acc_placa,
            "acc_char": acc_char
        }

    # --- 3. Combinar todos los resultados en un solo DataFrame ---
    # Empezamos con el DF de OCR
    df_combinado = df_ocr.copy()
    # Añadimos las predicciones de cada modelo YOLO
    for nombre, datos in resultados_yolo.items():
        df_combinado[f"pred_{nombre}"] = datos["df"]["pred_yolo"]

    # --- 4. Guardar CSV combinado ---
    archivo_csv = RESULT_DIR / "comparativa_yolo_ocr.csv"
    df_combinado.to_csv(archivo_csv, index=False)
    print(f"\n✅ CSV combinado guardado en: {archivo_csv}")

    # --- 5. Mostrar métricas ---
    print("\n" + "=" * 60)
    print("RESUMEN DE RESULTADOS")
    print("=" * 60)
    print(f"OCR        -> Placas correctas: {acc_placa_ocr:.2f}%  |  Caracteres: {acc_char_ocr:.2f}%")
    for nombre, datos in resultados_yolo.items():
        print(f"{nombre:10} -> Placas correctas: {datos['acc_placa']:.2f}%  |  Caracteres: {datos['acc_char']:.2f}%")
    print("=" * 60)

    # --- 6. (Opcional) Generar un archivo con solo las imágenes donde YOLO y OCR difieren ---
    # Esto puede ayudar a depurar
    df_diff = df_combinado[
        (df_combinado["pred_yolo"] != df_combinado["pred_ocr"]) |
        (df_combinado["pred_yolo"] != df_combinado["real"])
    ]
    if not df_diff.empty:
        archivo_diff = RESULT_DIR / "diferencias_yolo_ocr.csv"
        df_diff.to_csv(archivo_diff, index=False)
        print(f"✅ Archivo con diferencias guardado en: {archivo_diff}")