import os
import cv2
import time
from fastapi import FastAPI, Response
from fastapi.responses import HTMLResponse, StreamingResponse
# Importamos tu clase pura del archivo real 'myCarDetector.py'
from myCarDetector3 import ProcesadorTrafico

app = FastAPI(title="API Web Avanzada de Monitoreo de Tráfico")

# Instanciamos el motor de Inteligencia Artificial globalmente en el servidor
motor_ia = ProcesadorTrafico(modelo_path="yolov8n.pt", confianza=0.25)
motor_ia.resetear_memoria_tracker()

# Carpeta local por defecto que el servidor auditará para listar archivos
CARPETA_LOCAL = "sources_offline"

# Estructura maestra que almacena el estado de reproducción actual en internet
CONFIG_ESTADO = {
    "tipo": "video_local",
    "fuente": f"{CARPETA_LOCAL}/video.mp4",
    "actualizado": False  # Bandera de control para alertar cambios desde la interfaz
}




import yt_dlp

def obtener_captura_video(tipo, fuente):
    """Inicializa OpenCV extrayendo dinámicamente la mejor resolución de YouTube."""
    fuente_str = str(fuente).strip()
    print(f"[SERVIDOR] Conectando flujo -> Tipo: '{tipo}' | Fuente: '{fuente_str}'")
    
    if not fuente_str or fuente_str == "":
        return None

    if tipo == "youtube":
        try:
            # Configuración robusta para yt-dlp
            ydl_opts = {
                'quiet': True,
                'no_warnings': True,
                'format': 'best[ext=mp4]',  # Prioriza MP4
                'extract_flat': False,
                'ignoreerrors': True,
                'no_color': True,
                'geo_bypass': True,         # Intenta evitar bloqueos geográficos
                'socket_timeout': 30,
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(fuente_str, download=False)
                if info is None:
                    print("[ERROR YOUTUBE] No se pudo obtener información del video.")
                    return None
                # Buscar una URL de video directa
                # Puede estar en 'url' o en 'formats'
                if 'url' in info:
                    url_real = info['url']
                elif 'formats' and len(info['formats']) > 0:
                    # Elegir el mejor formato (último suele ser el de mayor calidad)
                    url_real = info['formats'][-1]['url']
                else:
                    print("[ERROR YOUTUBE] No se encontró ninguna URL de video.")
                    return None
                print(f"[SERVIDOR] URL extraída con éxito: {url_real[:80]}...")
                return cv2.VideoCapture(url_real)
                
        except Exception as error_yt:
            print(f"[ERROR YOUTUBE] Falló la extracción: {error_yt}")
            return None
    else:
        # Webcam, video local o m3u8
        origen = int(fuente_str) if fuente_str.isdigit() else fuente_str
        return cv2.VideoCapture(origen)






import yt_dlp

def obtener_captura_video2(tipo, fuente):
    """Inicializa OpenCV extrayendo dinámicamente la mejor resolución de YouTube."""
    fuente_str = str(fuente).strip()
    print(f"[SERVIDOR] Conectando flujo -> Tipo: '{tipo}' | Fuente: '{fuente_str}'")
    
    if not fuente_str or fuente_str == "":
        return None

    if tipo == "youtube":
        try:
            # Configuración robusta para yt-dlp
            ydl_opts = {
                'quiet': True,
                'no_warnings': True,
                'format': 'best[ext=mp4]',  # Prioriza MP4
                'extract_flat': False,
                'ignoreerrors': True,
                'no_color': True,
                'geo_bypass': True,         # Intenta evitar bloqueos geográficos
                'socket_timeout': 30,
            }
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(fuente_str, download=False)
                if info is None:
                    print("[ERROR YOUTUBE] No se pudo obtener información del video.")
                    return None
                # Buscar una URL de video directa
                # Puede estar en 'url' o en 'formats'
                if 'url' in info:
                    url_real = info['url']
                elif 'formats' and len(info['formats']) > 0:
                    # Elegir el mejor formato (último suele ser el de mayor calidad)
                    url_real = info['formats'][-1]['url']
                else:
                    print("[ERROR YOUTUBE] No se encontró ninguna URL de video.")
                    return None
                print(f"[SERVIDOR] URL extraída con éxito: {url_real[:80]}...")
                return cv2.VideoCapture(url_real)
                
        except Exception as error_yt:
            print(f"[ERROR YOUTUBE] Falló la extracción: {error_yt}")
            return None
    else:
        # Webcam, video local o m3u8
        origen = int(fuente_str) if fuente_str.isdigit() else fuente_str
        return cv2.VideoCapture(origen)



def obtener_captura_video1(tipo, fuente):
    """Inicializa OpenCV extrayendo dinámicamente la mejor resolución de YouTube."""
    fuente_str = str(fuente).strip()
    print(f"[SERVIDOR] Conectando flujo -> Tipo: '{tipo}' | Fuente: '{fuente_str}'")
    
    if not fuente_str or fuente_str == "":
        return None

    if tipo == "youtube":
        try:
            from cap_from_youtube import cap_from_youtube
            # CORRECCIÓN: Cambiamos '720p' por 'best' para que se adapte automáticamente
            # a cualquier resolución activa que tenga la transmisión en vivo.
            objeto_youtube = cap_from_youtube(fuente_str, 'best')
            
            url_real_stream = objeto_youtube.url if hasattr(objeto_youtube, 'url') else str(objeto_youtube)
            print(f"[SERVIDOR] URL extraída con éxito para OpenCV. Iniciando VideoCapture...")
            return cv2.VideoCapture(url_real_stream)
            
        except Exception as error_yt:
            print(f"[ERROR YOUTUBE] Enlace roto, restringido o fallo de yt-dlp: {error_yt}")
            return None
    else:
        # Esto procesa correctamente webcams (enteros), videos locales y m3u8 (strings)
        origen = int(fuente_str) if fuente_str.isdigit() else fuente_str
        return cv2.VideoCapture(origen)







def generar_streaming_video():
    """Bucle maestro del servidor adaptado para conmutar fuentes dinámicamente."""
    es_imagen = (CONFIG_ESTADO["tipo"] == "foto_local")
    cap = None
    
    # Intentamos abrir la fuente inicial
    if not es_imagen:
        cap = obtener_captura_video(CONFIG_ESTADO["tipo"], CONFIG_ESTADO["fuente"])
    
    CONFIG_ESTADO["actualizado"] = False
    motor_ia.resetear_memoria_tracker()

    while True:
        # VERIFICACIÓN DE INTERFAZ: Si el usuario cambió de video en la web, rompemos el bucle
        if CONFIG_ESTADO["actualizado"]:
            print("[SERVIDOR] Cambio de cámara detectado. Cerrando canal actual...")
            if cap is not None: 
                cap.release()
            break 

        # --- SOLUCIÓN AL ERROR CRÍTICO NoneType ---
        # Si la cámara o video falló al inicializarse (es None), pausamos el bucle 
        # de forma segura para no inundar la CPU y esperamos otra orden desde la web
        if not es_imagen and cap is None:
            print("[ALERTA] La captura actual es None. Esperando nueva fuente desde la interfaz...")
            time.sleep(1.0)
            continue

        if es_imagen:
            frame = cv2.imread(CONFIG_ESTADO["fuente"])
            if frame is None: 
                print("[ERROR] No se pudo cargar la foto local.")
                time.sleep(1.0)
                continue
        else:
            # Ahora es 100% seguro hacer el .read() porque ya validamos que 'cap' no es None
            ret, frame = cap.read()
            if not ret:
                if CONFIG_ESTADO["tipo"] == "video_local":
                    cap.set(cv2.CAP_PROP_POS_FRAMES, 0)
                    motor_ia.resetear_memoria_tracker()
                    continue
                else:
                    print("[INFO] Fin de la transmisión o cámara desconectada de internet.")
                    time.sleep(1.0)
                    continue

        try:
            # Enviamos el cuadro al núcleo puro de tu Inteligencia Artificial
            frame_procesado, autos_frame, conteos, flujo_in, flujo_out = motor_ia.procesar_fotograma(frame, es_imagen_estatica=es_imagen)
            
            # --- RENDERIZADO DEL CAJETÍN BLANCO EN EL SERVIDOR ---
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

            # Comprimir el cuadro resultante en formato JPEG
            _, buffer = cv2.imencode('.jpg', frame_procesado)
            yield (b'--frame\r\n' b'Content-Type: image/jpeg\r\n\r\n' + buffer.tobytes() + b'\r\n')
            
            if es_imagen: 
                time.sleep(0.1)
                
        except Exception as e:
            print(f"[ERROR CRÍTICO EN IA] Excepción en bucle de transmisión: {e}")
            break

    if cap is not None: 
        cap.release()





# ==============================================================================
# ENDPOINTS DE LA API (PUNTOS DE ACCESO WEB)
# ==============================================================================

@app.get("/", response_class=HTMLResponse)
def index_page():
    """Sirve la interfaz gráfica index.html al abrir la URL base."""
    with open("index.html", "r", encoding="utf-8") as f: 
        return f.read()

@app.get("/video_feed")
def video_feed():
    """Endpoint que emite la transmisión de video continua al navegador."""
    return StreamingResponse(generar_streaming_video(), media_type="multipart/x-mixed-replace; boundary=frame")

@app.get("/listar_archivos_locales")
def listar_archivos_locales():
    """Escanea la carpeta sources_offline y le avisa a la web qué archivos existen."""
    if not os.path.exists(CARPETA_LOCAL):
        return {"videos": [], "fotos": []}
    
    todos_los_archivos = os.listdir(CARPETA_LOCAL)
    
    # Filtramos las extensiones de video e imágenes válidas
    videos = [f for f in todos_los_archivos if f.lower().endswith(('.mp4', '.avi', '.mkv', '.mov'))]
    fotos = [f for f in todos_los_archivos if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp'))]
    
    return {"videos": videos, "fotos": fotos}

@app.post("/buscar_en_disco")
def buscar_en_disco(datos: dict):
    """Despierta a Tkinter local para poder examinar todo el disco duro de Windows."""
    tipo = datos.get("tipo")
    
    import tkinter as tk
    from tkinter import filedialog
    
    root = tk.Tk()
    root.withdraw()
    root.attributes("-topmost", True)  # Forzar a que la ventana de búsqueda salga al frente
    
    ruta_seleccionada = ""
    if tipo == "video_local":
        ruta_seleccionada = filedialog.askopenfilename(title="Selecciona Video", initialdir=os.getcwd(), filetypes=[("Videos", "*.mp4 *.avi *.mkv")])
    elif tipo == "foto_local":
        ruta_seleccionada = filedialog.askopenfilename(title="Selecciona Imagen", initialdir=os.getcwd(), filetypes=[("Imágenes", "*.jpg *.png *.jpeg")])
        
    root.quit()
    root.destroy()  # Destrucción forzada inmediata para liberar memoria gráfica
    
    if ruta_seleccionada:
        return {"status": "success", "ruta": ruta_seleccionada}
    return {"status": "cancelado", "ruta": ""}

@app.post("/cambiar_fuente")
def cambiar_fuente(datos: dict):
    """Recibe la orden de conmutación desde los selectores del navegador web."""
    CONFIG_ESTADO["tipo"] = datos.get("tipo_fuente")
    CONFIG_ESTADO["fuente"] = datos.get("url_fuente")
    CONFIG_ESTADO["actualizado"] = True  # Alerta al bucle principal de cambiar la fuente
    return {"status": "success"}




@app.post("/interaccion")
def registrar_interaccion(datos: dict):
    """Recibe los clics del mouse de la web y manipula los atributos de la clase de IA."""
    tipo_click = datos.get("tipo")
    x = datos.get("x")
    y = datos.get("y")
    
    if tipo_click == "izquierdo":
        # 1. Agregamos el clic a la lista acumulada
        motor_ia.clics_acumulados.append([x, y])
        print(f"[WEB] Clic izquierdo en: X={x}, Y={y}")

        # 2. Si es el primer clic, lo guardamos como P1
        if len(motor_ia.clics_acumulados) == 1:
            motor_ia.p1 = [x, y]
        
        # 3. Si es el segundo clic, definimos P1 y P2 definitivos
        elif len(motor_ia.clics_acumulados) == 2:
            # CORRECCIÓN CLAVE: Asignamos el PRIMER punto a P1 y el SEGUNDO a P2
            motor_ia.p1 = motor_ia.clics_acumulados[0]  # [x1, y1]
            motor_ia.p2 = motor_ia.clics_acumulados[1]  # [x2, y2]
            
            # Limpiamos la lista acumulada para la próxima vez
            motor_ia.clics_acumulados.clear()
            
            print(f"[WEB] Línea calibrada: P1={motor_ia.p1} -> P2={motor_ia.p2}")
            
    elif tipo_click == "derecho":
        motor_ia.cajetin_x = x
        motor_ia.cajetin_y = y
        print(f"[WEB] Cajetín desplazado a: X={x}, Y={y}")
        
    return {"status": "success"}
