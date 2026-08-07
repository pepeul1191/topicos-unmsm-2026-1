import cv2
import numpy as np
import cairosvg
import io
import random
import math
from pathlib import Path
from PIL import Image

def svg_a_numpy(svg_path):
  """Convierte el SVG a un array BGRA de OpenCV con transparencia."""
  png_bytes = cairosvg.svg2png(url=str(svg_path))
  pil_img = Image.open(io.BytesIO(png_bytes)).convert("RGBA")
  return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGBA2BGRA)

def generar_matriz_perspectiva_3d(w_letra, h_letra, canvas_size=(640, 640), max_grados=45):
  """Calcula la matriz de perspectiva simulando rotación 3D en los ejes X, Y, Z."""
  canvas_h, canvas_w = canvas_size

  # 1. Ángulos aleatorios en radianes entre -45° y +45°
  rx = math.radians(random.uniform(-max_grados, max_grados)) # Cabeceo (Pitch)
  ry = math.radians(random.uniform(-max_grados, max_grados)) # Guiñada (Yaw)
  rz = math.radians(random.uniform(-max_grados, max_grados)) # Pandeo (Roll)

  # 2. Matrices de rotación 3D
  Rx = np.array([
    [1, 0, 0],
    [0, math.cos(rx), -math.sin(rx)],
    [0, math.sin(rx), math.cos(rx)]
  ])

  Ry = np.array([
    [math.cos(ry), 0, math.sin(ry)],
    [0, 1, 0],
    [-math.sin(ry), 0, math.cos(ry)]
  ])

  Rz = np.array([
    [math.cos(rz), -math.sin(rz), 0],
    [math.sin(rz), math.cos(rz), 0],
    [0, 0, 1]
  ])

  # Matriz de rotación 3D combinada
  R = Rz @ Ry @ Rx

  # 3. Esquinas 3D centradas en el origen
  pts_3d = np.array([
    [-w_letra / 2, -h_letra / 2, 0],
    [ w_letra / 2, -h_letra / 2, 0],
    [ w_letra / 2,  h_letra / 2, 0],
    [-w_letra / 2,  h_letra / 2, 0]
  ]).T

  # Aplicar la rotación 3D a los puntos
  pts_rotados = R @ pts_3d

  # 4. Proyección en perspectiva (distancia focal simula el lente de cámara)
  focal = max(w_letra, h_letra) * 1.5
  dst_pts = []

  for i in range(4):
    x_3d, y_3d, z_3d = pts_rotados[:, i]
    factor_z = focal / (focal + z_3d) # División por Z para profundidad
    x_2d = x_3d * factor_z + (canvas_w / 2)
    y_2d = y_3d * factor_z + (canvas_h / 2)
    dst_pts.append([x_2d, y_2d])

  src_pts = np.float32([
    [0, 0],
    [w_letra, 0],
    [w_letra, h_letra],
    [0, h_letra]
  ])

  # Matriz final de perspectiva M
  M = cv2.getPerspectiveTransform(src_pts, np.float32(dst_pts))
  return M, src_pts

def mezclar_con_fondo(fondo, letra_deformada):
  """Superpone la letra con transparencia sobre el fondo."""
  alpha_s = letra_deformada[:, :, 3] / 255.0
  alpha_l = 1.0 - alpha_s
  resultado = fondo.copy()
  for c in range(0, 3):
    resultado[:, :, c] = (alpha_s * letra_deformada[:, :, c] + alpha_l * fondo[:, :, c])
  return resultado

def generar_dataset_rotaciones(ruta_svg, carpeta_destino, caracter, class_id, num_muestras=200, max_grados=45):
  """Genera N imágenes variando la perspectiva y crea sus etiquetas YOLO."""
  dir_images = Path(carpeta_destino) / "images"
  dir_labels = Path(carpeta_destino) / "labels"
  dir_images.mkdir(parents=True, exist_ok=True)
  dir_labels.mkdir(parents=True, exist_ok=True)

  img_letra = svg_a_numpy(ruta_svg)
  h_letra, w_letra = img_letra.shape[:2]
  canvas_size = (640, 640)
  canvas_h, canvas_w = canvas_size

  for i in range(1, num_muestras + 1):
    # 1. Matriz 3D aleatoria hasta max_grados
    M, src_pts = generar_matriz_perspectiva_3d(w_letra, h_letra, canvas_size, max_grados=max_grados)

    # 2. Deformar imagen
    letra_deformada = cv2.warpPerspective(
      img_letra, M, (canvas_w, canvas_h),
      flags=cv2.INTER_LANCZOS4,
      borderMode=cv2.BORDER_CONSTANT,
      borderValue=(0, 0, 0, 0)
    )

    # 3. Transformar esquinas para calcular el Bounding Box de YOLO
    src_pts_reshaped = src_pts.reshape(-1, 1, 2)
    dst_transformados = cv2.perspectiveTransform(src_pts_reshaped, M).squeeze()

    xs = dst_transformados[:, 0]
    ys = dst_transformados[:, 1]

    xmin, xmax = max(0, np.min(xs)), min(canvas_w, np.max(xs))
    ymin, ymax = max(0, np.min(ys)), min(canvas_h, np.max(ys))

    box_w = xmax - xmin
    box_h = ymax - ymin

    x_center = (xmin + box_w / 2.0) / canvas_w
    y_center = (ymin + box_h / 2.0) / canvas_h
    norm_w = box_w / canvas_w
    norm_h = box_h / canvas_h

    # Usa el class_id dinámico según el diccionario
    etiqueta_yolo = f"{class_id} {x_center:.6f} {y_center:.6f} {norm_w:.6f} {norm_h:.6f}"

    # 4. Fondo aleatorio
    val_gris = random.randint(160, 240)
    fondo = np.full((canvas_h, canvas_w, 3), (val_gris, val_gris, val_gris), dtype=np.uint8)

    # 5. Fusionar
    imagen_final = mezclar_con_fondo(fondo, letra_deformada)

    # 6. Guardar usando el carácter como prefijo (ej: A_001.jpg, A_001.txt)
    nombre_base = f"{caracter}_{i:03d}"
    cv2.imwrite(str(dir_images / f"{nombre_base}.jpg"), imagen_final)
    with open(dir_labels / f"{nombre_base}.txt", "w") as f:
      f.write(etiqueta_yolo + "\n")
      
# ==========================================
# EJECUCIÓN ITERANDO EL DICCIONARIO DE CLASES
# ==========================================
if __name__ == "__main__":
  # Mapeo de caracteres a ID de YOLO (incluyendo el guión)
  CLASES = {
    'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4,
    'F': 5, 'G': 6, 'H': 7, 'I': 8, 'J': 9,
    'K': 10, 'L': 11, 'M': 12, 'N': 13, 'O': 14,
    'P': 15, 'Q': 16, 'R': 17, 'S': 18, 'T': 19,
    'U': 20, 'V': 21, 'W': 22, 'X': 23, 'Y': 24, 'Z': 25,
    '0': 26, '1': 27, '2': 28, '3': 29, '4': 30,
    '5': 31, '6': 32, '7': 33, '8': 34, '9': 35,
    '-': 36  # Carácter de separación de placas
  }

  script_dir = Path(__file__).resolve().parent

  # Carpeta origen donde están los SVGs (ej: ../docs/A.svg, ../docs/-.svg, etc.)
  carpeta_svgs = script_dir.parent / "docs"

  # Carpeta donde se guardará el dataset
  carpeta_salida = script_dir / "dataset"

  for caracter, class_id in CLASES.items():
    # Definir el nombre del archivo SVG
    ruta_svg = carpeta_svgs / f"{caracter}.svg"
    
    # Manejo especial si guardaste el guión con la palabra 'guion.svg'
    if caracter == '-' and not ruta_svg.exists():
      ruta_svg = carpeta_svgs / "guion.svg"

    # Nombre seguro para los archivos generados
    nombre_prefijo = "guion" if caracter == '-' else caracter

    if ruta_svg.exists():
      print(f"Generando muestras para '{caracter}' (Class ID: {class_id})...")
      generar_dataset_rotaciones(
        ruta_svg=ruta_svg,
        carpeta_destino=carpeta_salida,
        caracter=nombre_prefijo,
        class_id=class_id,
        num_muestras=200,
        max_grados=45
      )
    else:
      print(f"Omitido: No se encontró '{ruta_svg.name}' en '{carpeta_svgs}'")

  print("\n¡Generación finalizada! Imágenes y etiquetas de los 37 caracteres guardadas.")