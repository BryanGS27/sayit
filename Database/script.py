import os
import psycopg2

# Configura tus datos de conexión
DB_HOST = "localhost"
DB_NAME = "say_it_database"
DB_USER = "postgres"
DB_PASSWORD = "Juanes123"
DB_PORT = "5432"

# Ruta de la carpeta donde están los videos
CARPETA_VIDEOS = "C:/Users/bryan/Documents/Projects/Flutter/sayit/Database/videos"

# Conexión a la base de datos
conn = psycopg2.connect(
    host=DB_HOST,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    port=DB_PORT
)
cur = conn.cursor()

# Extensiones de video que se aceptan
EXTENSIONES_VALIDAS = (".mp4", ".avi", ".mov", ".mkv")

# Recorremos los archivos en la carpeta
for archivo_nombre in os.listdir(CARPETA_VIDEOS):
    if archivo_nombre.lower().endswith(EXTENSIONES_VALIDAS):
        # Nombre sin extensión
        nombre_sin_extension = os.path.splitext(archivo_nombre)[0]

        ruta_completa = os.path.join(CARPETA_VIDEOS, archivo_nombre)
        with open(ruta_completa, "rb") as archivo:
            binario = archivo.read()
            cur.execute(
                "INSERT INTO videos (nombre, video) VALUES (%s, %s)",
                (nombre_sin_extension, binario)
            )
            print(f"✅ Video subido: {nombre_sin_extension}")

# Guardar y cerrar conexión
conn.commit()
cur.close()
conn.close()

print("🎉 Todos los videos han sido subidos correctamente.")
