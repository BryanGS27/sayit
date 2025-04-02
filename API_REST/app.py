from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import JSONResponse
import cv2
import mediapipe as mp
import joblib
import numpy as np
import os
from typing import Optional
from pydantic import BaseModel
import uvicorn

# Configuración
MODEL_PATH = 'modelos/modelo_señas_rf.pkl'
SCALER_PATH = 'modelos/scaler.pkl'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg'}

# Inicializar FastAPI
app = FastAPI(
    title="API de Reconocimiento de Señas",
    description="API para detectar señas de manos usando MediaPipe y Random Forest",
    version="1.0.0"
)

# Cargar modelo y scaler (con manejo de errores)
try:
    model = joblib.load(MODEL_PATH)
    scaler = joblib.load(SCALER_PATH)
except Exception as e:
    raise RuntimeError(f"Error al cargar el modelo: {str(e)}")

# Configurar MediaPipe
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=True,
    max_num_hands=1,
    min_detection_confidence=0.7
)

class PredictionResponse(BaseModel):
    prediction: str
    confidence: float
    status: str = "success"

def process_image(image: np.ndarray) -> Optional[dict]:
    """Procesa la imagen y devuelve la predicción"""
    try:
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        results = hands.process(image_rgb)
        
        if not results.multi_hand_landmarks:
            return None
            
        landmarks = []
        for lm in results.multi_hand_landmarks[0].landmark:
            landmarks.extend([lm.x, lm.y, lm.z])
            
        landmarks_normalized = scaler.transform([landmarks])
        prediction = model.predict(landmarks_normalized)[0]
        confidence = float(np.max(model.predict_proba(landmarks_normalized)) * 100)
        
        return {
            "prediction": prediction,
            "confidence": confidence
        }
    except Exception as e:
        raise RuntimeError(f"Error en procesamiento: {str(e)}")

@app.post("/predict", response_model=PredictionResponse)
async def predict_sign(
    file: UploadFile = File(..., description="Imagen de la seña a predecir")
):
    """Endpoint para reconocer señas de manos"""
    
    # Validar extensión
    extension = file.filename.split('.')[-1].lower()
    if extension not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"Formato no soportado. Use: {', '.join(ALLOWED_EXTENSIONS)}"
        )
    
    try:
        # Leer imagen directamente sin guardar
        contents = await file.read()
        image = cv2.imdecode(np.frombuffer(contents, np.uint8), cv2.IMREAD_COLOR)
        
        if image is None:
            raise HTTPException(status_code=400, detail="No se pudo leer la imagen")
        
        result = process_image(image)
        if not result:
            raise HTTPException(status_code=400, detail="No se detectaron manos")
            
        return {
            "prediction": result["prediction"],
            "confidence": result["confidence"]
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Error en el servidor: {str(e)}"
        )

@app.get("/health")
async def health_check():
    """Endpoint de verificación de salud"""
    return {"status": "healthy"}

""" if _name_ == "_main_":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    ) """

""" 📌 requirements.txt
Copy
fastapi==0.95.2
uvicorn==0.22.0
opencv-python==4.7.0.72
mediapipe==0.10.0
scikit-learn==1.2.2
joblib==1.2.0
numpy==1.24.3
python-multipart==0.0.6
🚀 Cómo ejecutar:
bash
Copy
# Instalar dependencias
pip install -r requirements.txt

# Iniciar servidor (desarrollo)
uvicorn app:app --reload

# Producción (con Gunicorn)
gunicorn -w 4 -k uvicorn.workers.UvicornWorker app:app
📡 Ejemplo de Uso (Cliente):
python
Copy
import requests

url = "http://localhost:8000/predict"
files = {"file": open("ejemplo.jpg", "rb")}

response = requests.post(url, files=files)
print(response.json())
✅ Respuestas Esperadas:
Éxito:

json
Copy
{
  "prediction": "A",
  "confidence": 95.7,
  "status": "success"
}
Errores:

json
Copy
{
  "detail": "No se detectaron manos"
}
🔍 Características Clave:
Validación estricta de tipos y formatos

Documentación automática en /docs y /redoc

Manejo eficiente de memoria: No guarda archivos temporalmente

Endpoint de salud para monitoreo

Tipado fuerte con Pydantic

Optimizado para producción con Gunicorn+Uvicorn

🛠 Mejoras Adicionales (Opcionales):
Autenticación JWT:

python
Copy
from fastapi.security import OAuth2PasswordBearer
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")
Rate Limiting:

python
Copy
from fastapi import Request
from fastapi.middleware import Middleware
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
CORS:

python
Copy
from fastapi.middleware.cors import CORSMiddleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"]
) """