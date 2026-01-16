"""
Main Application Module.

Configura a instância FastAPI, middlewares e inclui os routers.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger

app = FastAPI(
    title="YouTube Downloader API",
    description="API para download e streaming de vídeos do YouTube",
    version="1.0.0"
)

# Configuração de CORS - Permite tudo no MVP para facilitar dev mobile/web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

from app.api.v1.endpoints import download

from fastapi.staticfiles import StaticFiles
from app.core.config import get_settings

app.include_router(download.router, prefix="/api/v1/download", tags=["download"])



@app.on_event("startup")
async def startup_event():
    logger.info("Servidor iniciado!")

@app.get("/health")
async def health_check():
    return {"status": "ok", "version": "1.0.0"}
