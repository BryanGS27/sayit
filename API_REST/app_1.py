#SERVIDOR DE FAST-API

from fastapi import FastAPI
import uvicorn

app = FastAPI()


@app.get("/health")
async def health_check():
    """Endpoint de verificación de salud"""
    return {"status": "healthy"}

if _name_ == "_main_":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )

    