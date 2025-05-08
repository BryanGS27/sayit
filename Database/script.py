import os
import psycopg2

# Configura tus datos de conexión
DB_HOST = "localhost"
DB_NAME = "say_it_database"
DB_USER = "sayitadmin"
DB_PASSWORD = "Juanes123UWU"
DB_PORT = "5432"

# Ruta de la carpeta donde están los archivos
#CARPETA_VIDEOS = "C:/Users/bryan/Documents/Projects/Flutter/sayit/Database/videos"
CARPETA_VIDEOS = "/root/sayit/Database/videos"

# Clasificamos extensiones
EXTENSIONES_VIDEO = (".mp4", ".avi", ".mov", ".mkv")
EXTENSIONES_IMAGEN = (".png", ".jpg", ".jpeg")

# Conexión a la base de datos
try:
    conn = psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )
    print("✅ Conexión exitosa a la base de datos")
    cur = conn.cursor()

    # Recorremos los archivos en la carpeta
    for archivo_nombre in os.listdir(CARPETA_VIDEOS):
        archivo_ext = os.path.splitext(archivo_nombre)[1].lower()

        if archivo_ext in EXTENSIONES_VIDEO + EXTENSIONES_IMAGEN:
            nombre_sin_extension = os.path.splitext(archivo_nombre)[0]
            tipo = "video" if archivo_ext in EXTENSIONES_VIDEO else "imagen"

            ruta_completa = os.path.join(CARPETA_VIDEOS, archivo_nombre)
            with open(ruta_completa, "rb") as archivo:
                binario = archivo.read()
                cur.execute(
                    "INSERT INTO videos (nombre, video, tipo) VALUES (%s, %s, %s)",
                    (nombre_sin_extension, binario, tipo)
                )
                print(f"✅ Archivo subido: {nombre_sin_extension} ({tipo})")

    # Guardar y cerrar conexión
    conn.commit()
    cur.close()
    conn.close()
    print("🎉 Todos los archivos han sido subidos correctamente.")

except psycopg2.OperationalError as e:
    print("❌ Error de conexión:")
    print(e.pgerror or str(e))
