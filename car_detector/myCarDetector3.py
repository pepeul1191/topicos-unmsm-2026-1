import os
import time
from pathlib import Path
from copy import deepcopy
import cv2
import torch
from ultralytics import YOLO
from datetime import datetime, timedelta

# ==============================================================================
# CONFIGURACIÓN DE GUARDADO DE FRAMES
# ==============================================================================
CARPETA_SALIDA = "output_frames"   # Carpeta base donde se guardarán los PNG y TXT

# ==============================================================================
# MÓDULO 1: MOTOR DE INTELIGENCIA ARTIFICIAL Y LÓGICA DE CONTEO (EL "NÚCLEO")
# ==============================================================================
class ProcesadorTrafico:
    """Clase autónoma encargada de la inferencia, tracking y conteo de vehículos."""
    
    def __init__(self, modelo_path="yolov11s.pt", confianza=0.25):
        self.device = 0 if torch.cuda.is_available() else "cpu"
        self.model = YOLO(modelo_path)
        self.confianza = confianza
        
        # --- GEOMETRÍA DIAGONAL ---
        self.p1 = [50, 300]   # Extremo izquierdo de la línea [X1, Y1]
        self.p2 = [950, 300]  # Extremo derecho de la línea   [X2, Y2]
        self.clics_acumulados = []

        # --- NUEVO: Coordenadas iniciales del Cajetín Movible (Esquina Superior Izquierda) ---
        self.cajetin_x = 10
        self.cajetin_y = 10

        # Estructuras de datos de conteo
        self.counter = {"entradas": 0, "salidas": 0}
        self.detections = {} 

        # Histórico de tiempo para vehículos/minuto
        self.tiestamps_entradas = []
        self.tiestamps_salidas = []
        self.ventana_tiempo = 5.0 

        # --- Almacenar las últimas detecciones para guardar etiquetas ---
        self.ultimas_detecciones = []  # Lista de tuplas (class_id, x_center, y_center, width, height) normalizadas

    def resetear_memoria_tracker(self):
        """Reinicia el histórico de IDs y estadísticas."""
        if self.model.predictor:
            trackers = getattr(self.model.predictor, 'trackers', None) or getattr(self.model.predictor, 'tracker_map', {}).values()
            for tracker in trackers:
                if hasattr(tracker, 'reset_id'): 
                    tracker.reset_id()
        self.detections.clear()
        self.counter = {"entradas": 0, "salidas": 0}
        self.tiestamps_entradas.clear()
        self.tiestamps_salidas.clear()

    def click_mouse_interactivo(self, evento, x, y, banderas, parametros):
        """Maneja el ratón de forma dual: Clic izquierdo para la línea, Clic derecho para el cajetín."""
        if evento == cv2.EVENT_LBUTTONDOWN:
            self.clics_acumulados.append([x, y])
            print(f"[GEOMETRÍA] Clic izquierdo en: X={x}, Y={y}")
            if len(self.clics_acumulados) == 1:
                self.p1 = [x, y]
            elif len(self.clics_acumulados) == 2:
                self.p1 = self.clics_acumulados[0]
                self.p2 = self.clics_acumulados[1]
                print(f"[GEOMETRÍA] Línea diagonal fijada: P1={self.p1} -> P2={self.p2}")
                self.clics_acumulados.clear()
        elif evento == cv2.EVENT_RBUTTONDOWN:
            self.cajetin_x = x
            self.cajetin_y = y
            print(f"[INTERFAZ] Cajetín movido a la posición: X={x}, Y={y}")

    def _evaluar_lado_linea(self, x, y):
        """Calcula el producto cruzado vectorial para determinar la posición relativa a la diagonal."""
        x1, y1 = self.p1
        x2, y2 = self.p2
        return (x2 - x1) * (y - y1) - (y2 - y1) * (x - x1)

    def calcular_flujo_por_minuto(self):
        """Calcula el flujo dinámico de vehículos/minuto usando la ventana deslizante."""
        ahora = time.time()
        self.tiestamps_entradas = [t for t in self.tiestamps_entradas if ahora - t <= self.ventana_tiempo]
        self.tiestamps_salidas = [t for t in self.tiestamps_salidas if ahora - t <= self.ventana_tiempo]
        
        flujo_entradas = (len(self.tiestamps_entradas) / self.ventana_tiempo) * 60.0
        flujo_salidas = (len(self.tiestamps_salidas) / self.ventana_tiempo) * 60.0
        return flujo_entradas, flujo_salidas

    def procesar_fotograma(self, frame, es_imagen_estatica=False):
        """Recibe el frame bruto, procesa la IA, calcula conteo en diagonal y retorna la info.
           Además, guarda en self.ultimas_detecciones las detecciones normalizadas para etiquetado.
        """
        img_canvas = deepcopy(frame)
        
        # Dibujar la línea divisoria (Grosor elegante de 2px)
        cv2.line(img_canvas, tuple(self.p1), tuple(self.p2), (255, 0, 255), 2)

        # Inferencia de YOLOv8 filtrando estrictamente vehículos urbanos
        if es_imagen_estatica:
            resultados = self.model.predict(source=frame, conf=self.confianza, imgsz=640, device=self.device, verbose=False, classes=[2, 3, 5, 7])
        else:
            resultados = self.model.track(source=frame, conf=self.confianza, iou=0.7, imgsz=640, persist=True, device=self.device, verbose=False, classes=[2, 3, 5, 7])

        carros_en_este_frame = 0
        current_frame_ids = set()
        detecciones_normalizadas = []  # Para guardar en self.ultimas_detecciones

        for result in resultados:
            if result.boxes is None:
                continue
                
            tiene_ids = result.boxes.id is not None
            carros_en_este_frame = len(result.boxes.cls)

            for idx in range(carros_en_este_frame):
                clase_name = self.model.names[int(result.boxes.cls[idx])]
                class_id = int(result.boxes.cls[idx])
                track_id = int(result.boxes.id[idx]) if tiene_ids else 0
                
                if tiene_ids:
                    current_frame_ids.add(track_id)

                # Cajas delgadas de 1px sin centroides invasivos
                x1, y1, x2, y2 = map(int, result.boxes.xyxy[idx])
                cv2.rectangle(img_canvas, (x1, y1), (x2, y2), (0, 255, 0), 1)
                
                center_x = int((x1 + x2) / 2)
                center_y = int((y1 + y2) / 2)
                
                # Texto ultra limpio solicitado en los boxes (Sin ":" ni "|")
                texto = f"{track_id} {clase_name}" if tiene_ids else clase_name
                cv2.putText(img_canvas, texto, (x1, y1 - 7), cv2.FONT_HERSHEY_SIMPLEX, 0.4, (0, 255, 0), 1)

                # Obtener coordenadas normalizadas para el archivo de etiquetas
                # Ultralytics devuelve xywhn (centro x, centro y, ancho, alto) normalizados
                xywhn = result.boxes.xywhn[idx].cpu().numpy()
                x_center, y_center, width, height = xywhn
                detecciones_normalizadas.append((class_id, x_center, y_center, width, height))

                # Análisis de cruce en diagonal
                if tiene_ids:
                    lado_actual = self._evaluar_lado_linea(center_x, center_y)
                    
                    if track_id in self.detections:
                        lado_anterior = self.detections[track_id]["lado_previo"]
                        
                        if lado_anterior <= 0 and lado_actual > 0:
                            self.counter["entradas"] += 1
                            self.tiestamps_entradas.append(time.time())
                        elif lado_anterior >= 0 and lado_actual < 0:
                            self.counter["salidas"] += 1
                            self.tiestamps_salidas.append(time.time())
                            
                        self.detections[track_id]["lado_previo"] = lado_actual
                    else:
                        self.detections[track_id] = {"lado_previo": lado_actual, "count_not_detected": 0}

        # Limpieza de memoria RAM del tracker
        if tiene_ids:
            for key in list(self.detections.keys()):
                if key not in current_frame_ids:
                    self.detections[key]['count_not_detected'] += 1
                    if self.detections[key]['count_not_detected'] >= 30:
                        del self.detections[key]

        # Guardar las detecciones normalizadas para posible guardado de etiquetas
        self.ultimas_detecciones = detecciones_normalizadas

        flujo_in, flujo_out = self.calcular_flujo_por_minuto()
        return img_canvas, carros_en_este_frame, self.counter, flujo_in, flujo_out


# ==============================================================================
# REPOSITORIOS DE FUENTES (PARA MENÚ CONSOLA) - ACTUALIZADOS
# ==============================================================================

LISTA_YOUTUBE = {
    1: {"desc": "Tokio, Japón (En Vivo)", "url": "https://www.youtube.com/watch?v=dfVK7ld38Ys"},
    2: {"desc": "Michigan, USA (En Vivo)", "url": "https://www.youtube.com/watch?v=1H0iTzv2jiQ"},
    3: {"desc": "Tokio, Japón (En Vivo 2)", "url": "https://www.youtube.com/watch?v=6dp-bvQ7RWo"},
    4: {"desc": "Wyoming, USA (En Vivo)", "url": "https://www.youtube.com/watch?v=1EiC9bvVGnk"},
    5: {"desc": "Kentucky, USA (En Vivo)", "url": "https://www.youtube.com/watch?v=9SLt3AT0rXk"},
    6: {"desc": "Países Bajos (En Vivo)", "url": "https://www.youtube.com/watch?v=Jy1Y9f8NEY0"},
    7: {"desc": "Pista Offline - Lista 1", "url": "https://www.youtube.com/watch?v=Y7Kv_oJtuJE&list=PLYi4RzopXMXedDuTHEaTHNWpaujs7sKpA"},
    8: {"desc": "Pista Offline - Lista 1 (Índice 4)", "url": "https://www.youtube.com/watch?v=UerNqtdjGkQ&list=PLYi4RzopXMXedDuTHEaTHNWpaujs7sKpA&index=4"},
    9: {"desc": "Pista Offline - Con timecode", "url": "https://www.youtube.com/watch?v=MNn9qKG2UFI&t=7s"},
    10: {"desc": "Pista Offline - Lista 2", "url": "https://www.youtube.com/watch?v=wqctLW0Hb_0&list=PLJKyZ_NuOhJQzif2-6-Kq9OiOj_UjJWvi"},
}

LISTA_STREAMING = {
    1: {"desc": "Lima, Perú - Paseo de la República", "url": "https://live.smartechlatam.online/claro/paseodelarepublica/index.m3u8"},
    2: {"desc": "Lima, Perú - Av. Angamos", "url": "https://live.smartechlatam.online/claro/angamos/index.m3u8"},
    3: {"desc": "Lima, Perú - Paradero Gallinazos, Puente Pïedra", "url": "https://live.smartechlatam.online/claro/gallinazos/index.m3u8"},
    4: {"desc": "Lima, Perú - Panamericana Sur, Santiago de Surco", "url": "https://live.smartechlatam.online/claro/panamericana/index.m3u8"},
    5: {"desc": "Lima, Perú - El Derby, Santiago de Surco", "url": "https://live.smartechlatam.online/claro/derby/index.m3u8"},
    6: {"desc": "Lima, Perú - Prolongación Tacna, Rimac", "url": "https://live.smartechlatam.online/claro/prolongaciontacna/index.m3u8"},
    7: {"desc": "Lima, Perú - Panamericana Sur, Punta Hermosa", "url": "https://live.smartechlatam.online/claro/domo_quebrada_seca/index.m3u8"},
    8: {"desc": "Lima, Perú - Av. Brasil con Javier Prado, Magdalena", "url": "https://live.smartechlatam.online/claro/brasilconjavierprado/index.m3u8"},
    9: {"desc": "Lima, Perú - Av. La Marina, Pueblo Libre", "url": "https://live.smartechlatam.online/claro/lamarina/index.m3u8"},
    10: {"desc": "Lima, Perú - Av. La Marina, Pueblo Libre", "url": "https://live.smartechlatam.online/claro/domo_punta_negra/index.m3u8"},
    11: {"desc": "Lima, Perú - Paradero Escuela PNP, Puente Piedra", "url": "https://live.smartechlatam.online/claro/escuela_pnp/index.m3u8"},     
    12: {"desc": "Lima, Perú - Peaje Plaza Villa, VES", "url": "https://live.smartechlatam.online/claro/plaza_villa/index.m3u8"},
    13: {"desc": "Lima, Perú - Av. Javier Prado, Santiago de Surco", "url": "https://live.smartechlatam.online/claro/javierprado/index.m3u8"},
    14: {"desc": "Lima, Perú - Av. República de Panamá, Surquillo", "url": "https://live.smartechlatam.online/claro/republicapanama/index.m3u8"},
}

def seleccionar_fuente_consola():
    """
    Muestra el menú y retorna:
    - tipo_fuente: str (video_local, foto_local, webcam, youtube, m3u8)
    - u_fuente: str o int (ruta, URL o 0 para webcam)
    - prefijo: str ('yt' o 'mu' o 'local')
    - indice: int (número del video en la lista, 0 si no aplica)
    """
    print("\n==================================================")
    print("      SISTEMA DE CONTEO - MENÚ CONSOLA")
    print("==================================================")
    print("1. Video Local (sources_offline/video.mp4)")
    print("2. Foto Local (sources_offline/carro.jpg)")
    print("3. Cámara Web (Webcam Integrada)")
    print("4. Repositorio de Cámaras de YouTube")
    print("5. Repositorio de Flujos Streaming (.m3u8)")
    print("==================================================")
    
    try:
        opcion = int(input("Elige una opción (1-5): "))
    except ValueError:
        return None, None, None, None

    if opcion == 1:
        return "video_local", "sources_offline/video.mp4", "local", 0
    elif opcion == 2:
        return "foto_local", "sources_offline/carro.jpg", "local", 0
    elif opcion == 3:
        return "webcam", 0, "local", 0
    elif opcion == 4:
        print("\n--- Repositorio YouTube ---")
        for k, v in LISTA_YOUTUBE.items():
            print(f"{k}. {v['desc']}")
        print(f"{len(LISTA_YOUTUBE)+1}. Ingresar nueva URL")
        try:
            elec = int(input("Selecciona una opción: "))
        except ValueError:
            return None, None, None, None
        if elec in LISTA_YOUTUBE:
            return "youtube", LISTA_YOUTUBE[elec]["url"], "yt", elec
        else:
            url = input("Pega la URL de YouTube: ")
            return "youtube", url, "yt", 0  # índice 0 para personalizado
    elif opcion == 5:
        print("\n--- Repositorio Streaming M3U8 ---")
        for k, v in LISTA_STREAMING.items():
            print(f"{k}. {v['desc']}")
        print(f"{len(LISTA_STREAMING)+1}. Ingresar nueva URL M3U8")
        try:
            elec = int(input("Selecciona una opción: "))
        except ValueError:
            return None, None, None, None
        if elec in LISTA_STREAMING:
            return "m3u8", LISTA_STREAMING[elec]["url"], "mu", elec
        else:
            url = input("Pega la URL del flujo (.m3u8): ")
            return "m3u8", url, "mu", 0
    return None, None, None, None


# ==============================================================================
# FUNCIÓN AUXILIAR PARA SABER CUÁNDO ES EL PRÓXIMO INSTANTE DE GUARDADO
# ==============================================================================

def proximo_instante_guardado(intervalo_minutos):
    """
    Calcula el próximo timestamp (en segundos desde epoch) en el que
    los minutos del reloj sean múltiplos exactos del intervalo.
    Ej: intervalo=12 -> 6:00, 6:12, 6:24, ...
    """
    ahora = datetime.now()
    # Minutos transcurridos desde la medianoche
    minutos_desde_medianoche = ahora.hour * 60 + ahora.minute
    # Siguiente múltiplo del intervalo
    siguiente = ((minutos_desde_medianoche // intervalo_minutos) + 1) * intervalo_minutos
    # Diferencia en minutos hasta el próximo objetivo
    diff_minutos = siguiente - minutos_desde_medianoche
    # Calcular el timestamp objetivo
    objetivo = ahora + timedelta(minutes=diff_minutos)
    # Redondear a los segundos 00 (opcional, para mayor precisión)
    objetivo = objetivo.replace(second=0, microsecond=0)
    return objetivo.timestamp()


# ==============================================================================
# MÓDULO 4: ORQUESTADOR PRINCIPAL (ENTORNO LOCAL)
# ==============================================================================

def ejecutar_aplicacion():
    tipo_fuente, u_fuente, prefijo, indice = seleccionar_fuente_consola()
    if not u_fuente and tipo_fuente != "webcam":
        return

    # --- PEDIR INTERVALO EN MINUTOS ---
    try:
        intervalo_minutos = int(input("Intervalo entre capturas (en minutos, ej: 12): "))
        if intervalo_minutos <= 0:
            raise ValueError
    except ValueError:
        print("Intervalo no válido. Se usará 12 minutos por defecto.")
        intervalo_minutos = 12

    es_imagen = (tipo_fuente == "foto_local")
    if tipo_fuente == "youtube":
        from cap_from_youtube import cap_from_youtube
        cap = cv2.VideoCapture(cap_from_youtube(u_fuente, '720p'))
    else:
        cap = cv2.VideoCapture(u_fuente)

    nombre_ventana = "Sistema Modular Inteligente"
    motor_ia = ProcesadorTrafico(modelo_path="yolov8n.pt", confianza=0.25)
    motor_ia.resetear_memoria_tracker()

    cv2.namedWindow(nombre_ventana)
    cv2.setMouseCallback(nombre_ventana, motor_ia.click_mouse_interactivo)

    print("\n[MÓDULO INTERACTIVO ACTIVO]")
    print("-> Clic Izquierdo (Dos veces): Trazar o inclinar la línea divisoria.")
    print("-> Clic Derecho (En cualquier zona): Mover el cajetín blanco de estadísticas.")
    print(f"-> Guardado automático cada {intervalo_minutos} minutos, sincronizado con el reloj.")

    # Calcular el primer instante de guardado (próximo múltiplo del intervalo)
    proximo_guardado = proximo_instante_guardado(intervalo_minutos)
    print(f"-> Próximo guardado programado para: {datetime.fromtimestamp(proximo_guardado).strftime('%Y-%m-%d %H:%M:%S')}")

    while True:
        if es_imagen:
            frame = cv2.imread(u_fuente)
            if frame is None: 
                print("Error: No se pudo cargar la imagen.")
                break
        else:
            ret, frame = cap.read()
            if not ret: 
                print("Fin del video o del streaming.")
                break

        # Procesar el frame (obtenemos el frame procesado con dibujos)
        frame_procesado, autos_frame, conteos, flujo_in, flujo_out = motor_ia.procesar_fotograma(frame, es_imagen_estatica=es_imagen)

        # ------------------------------------------------------------
        # GUARDADO SINCRONIZADO CON EL RELOJ (HORAS EXACTAS)
        # ------------------------------------------------------------
        ahora_ts = time.time()
        if ahora_ts >= proximo_guardado:
            # Determinar si es día o noche (6am - 6pm = día)
            ahora_dt = datetime.now()
            hora = ahora_dt.hour
            if 6 <= hora < 18:
                subcarpeta = "dia"
                sufijo = "d"
            else:
                subcarpeta = "noche"
                sufijo = "n"

            # Construir nombre base: prefijo + indice + fecha_hora + sufijo
            fecha_str = ahora_dt.strftime("%Y_%m_%d_%H_%M")
            if prefijo == "yt" and indice > 0:
                base_nombre = f"yt{indice}_{fecha_str}_{sufijo}"
            elif prefijo == "mu" and indice > 0:
                base_nombre = f"mu{indice}_{fecha_str}_{sufijo}"
            else:
                # Si es local o personalizado, usar 'img' + timestamp
                base_nombre = f"img_{int(ahora_ts*1000)}_{sufijo}"

            # Ruta completa de la carpeta
            carpeta_destino = os.path.join(CARPETA_SALIDA, subcarpeta)
            os.makedirs(carpeta_destino, exist_ok=True)

            # Guardar frame original (sin procesar)
            ruta_png = os.path.join(carpeta_destino, f"{base_nombre}.png")
            cv2.imwrite(ruta_png, frame)
            print(f"[GUARDADO] Frame guardado: {ruta_png}")

            # Guardar archivo de etiquetas (formato YOLO)
            ruta_txt = os.path.join(carpeta_destino, f"{base_nombre}.txt")
            with open(ruta_txt, 'w') as f:
                for det in motor_ia.ultimas_detecciones:
                    class_id, xc, yc, w, h = det
                    f.write(f"{class_id} {xc:.6f} {yc:.6f} {w:.6f} {h:.6f}\n")
            print(f"[GUARDADO] Etiquetas guardadas: {ruta_txt}")

            # Calcular el próximo instante de guardado
            proximo_guardado = proximo_instante_guardado(intervalo_minutos)
            print(f"-> Próximo guardado programado para: {datetime.fromtimestamp(proximo_guardado).strftime('%Y-%m-%d %H:%M:%S')}")
        # ------------------------------------------------------------

        # Construcción del cajetín dinámico (igual que antes)
        ancho_cajetin = 330
        alto_cajetin = 125
        bx = motor_ia.cajetin_x
        by = motor_ia.cajetin_y

        cv2.rectangle(frame_procesado, (bx, by), (bx + ancho_cajetin, by + alto_cajetin), (255, 255, 255), thickness=-1)
        cv2.rectangle(frame_procesado, (bx, by), (bx + ancho_cajetin, by + alto_cajetin), (220, 220, 220), thickness=1)

        cv2.putText(frame_procesado, f"Vehiculos Frame: {autos_frame}", (bx + 15, by + 25), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 0), 1)
        cv2.putText(frame_procesado, f"Vehiculos/min (N -> S): {flujo_in:.1f} (Total: {conteos['entradas']})", (bx + 15, by + 55), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (255, 0, 0), 1)
        cv2.putText(frame_procesado, f"Vehiculos/min (S -> N): {flujo_out:.1f} (Total: {conteos['salidas']})", (bx + 15, by + 85), cv2.FONT_HERSHEY_SIMPLEX, 0.45, (0, 0, 255), 1)
        cv2.putText(frame_procesado, f"Linea P1:{motor_ia.p1} P2:{motor_ia.p2}", (bx + 15, by + 112), cv2.FONT_HERSHEY_SIMPLEX, 0.38, (120, 120, 120), 1)

        cv2.imshow(nombre_ventana, frame_procesado)

        if es_imagen or (cv2.waitKey(1) & 0xFF == ord('q')):
            break

    if not es_imagen: 
        cap.release()
    cv2.destroyAllWindows()
    print("Aplicación cerrada de forma limpia.")


if __name__ == "__main__":
    ejecutar_aplicacion()