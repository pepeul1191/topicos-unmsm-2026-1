import cv2
import re
from ultralytics import YOLO

# 1. Cargar modelo e imagen
model = YOLO('runs/exp_nano-5/weights/best.pt')
img = cv2.imread('PERU-PLACA-REGULAR.png')

if img is None:
    print("❌ No se encontró la imagen PERU-PLACA-REGULAR.png")
    exit()

h, w, _ = img.shape

# 2. Hacemos un recorte ajustado (Crop) para enfocar solo el centro donde están las letras
# (Descartamos los bordes blancos externos)
crop_y1, crop_y2 = int(h * 0.25), int(h * 0.90)
crop_x1, crop_x2 = int(w * 0.05), int(w * 0.95)
cropped_img = img[crop_y1:crop_y2, crop_x1:crop_x2]

# Guardar la imagen recortada para verificar visualmente
cv2.imwrite('placa_recortada_test.jpg', cropped_img)

# 3. Inferencia con 'rect=True' para mantener la proporción de aspecto sin deformar
results = model.predict(
    source=cropped_img, 
    conf=0.15, 
    imgsz=640, 
    rect=True,  # EVITA QUE YOLO APLASTE LA IMAGEN
    device='cpu'
)

detecciones = []
for result in results:
    if result.boxes is not None:
        for box in result.boxes:
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            conf = float(box.conf[0])
            cls_id = int(box.cls[0])
            char_name = result.names[cls_id]
            detecciones.append((x1, y1, x2, y2, char_name, conf))

# Ordenar de izquierda a derecha por coordenada X
detecciones.sort(key=lambda d: d[0])

print("\n" + "="*50)
print("🔎 RESULTADOS CON RECORTE Y ASPECT-RATIO CORREGIDO:")
for d in detecciones:
    print(f"  Letra/Número: '{d[4]}' | Confianza: {d[5]:.1%}")

raw_text = "".join([d[4] for d in detecciones])
clean_text = re.sub(r'[^A-Z0-9]', '', raw_text.upper())
formatted = f"{clean_text[:3]}-{clean_text[3:]}" if len(clean_text) == 6 else clean_text

print("="*50)
print(f"🇵🇪 Texto detectado final: {formatted}")
print("="*50 + "\n")