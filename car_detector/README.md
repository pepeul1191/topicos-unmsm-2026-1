## 🐍 Crear entorno virtual (backend)

### En Windows:

    > python -m venv venv
    > venv\Scripts\activate.bat
    > pip install -r requirements.txt

### En Linux:

    $ python3 -m venv venv
    $ source venv/bin/activate
    $ pip install -r requirements.txt


Python 3.10.18
Correr el servidor Python en terminmal de VSC
uvicorn server:app --host 127.0.0.1 --port 8000 --reload

Detener servidor
CTRL + C