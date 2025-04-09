from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import psycopg2
import base64
import spacy

# Crear el router
router = APIRouter()

# Cargar el modelo de spaCy solo una vez
nlp = spacy.load("es_core_news_sm")

# Configuración de la base de datos
DB_HOST = "localhost"
DB_NAME = "say_it_database"
DB_USER = "sayitadmin"
DB_PASSWORD = "Juanes123UWU"
DB_PORT = "5432"


# Modelo para recibir el texto
class TextoEntrada(BaseModel):
    texto: str

# Conexión a la base de datos
def obtener_conexion():
    return psycopg2.connect(
        host=DB_HOST,
        dbname=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        port=DB_PORT
    )

# Endpoint para obtener videos
@router.post("/obtener_video/")
async def obtener_video(texto: TextoEntrada):
    # Lematización con spaCy
    doc = nlp(texto.texto.lower())
    lemas = [token.lemma_ for token in doc]

    conn = obtener_conexion()
    cur = conn.cursor()
    videos_a_enviar = []

    try:
        for palabra in lemas:
            cur.execute("""
                SELECT v.nombre, v.video
                FROM videos v
                WHERE v.nombre = %s
                UNION
                SELECT s.forma, v.video
                FROM sinonimos s
                JOIN videos v ON v.id = s.palabra_id
                WHERE s.forma = %s
            """, (palabra, palabra))

            video = cur.fetchone()

            if video:
                nombre_video, contenido_video = video
                video_base64 = base64.b64encode(contenido_video).decode('utf-8')
                videos_a_enviar.append({
                    "nombre": nombre_video,
                    "video_base64": video_base64
                })

        if not videos_a_enviar:
            raise HTTPException(status_code=404, detail="No se encontraron videos para el texto ingresado.")

        return {"videos": videos_a_enviar}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cur.close()
        conn.close()
