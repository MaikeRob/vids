from pydantic_settings import BaseSettings
from functools import lru_cache
import os

class Settings(BaseSettings):
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "YouTube Downloader API"
    DOWNLOAD_DIR: str = os.path.join(os.getcwd(), "downloads")

    # Configurações do YT-DLP
    YTDLP_FORMAT: str = "bestvideo+bestaudio/best"

    class Config:
        case_sensitive = True

@lru_cache()
def get_settings():
    return Settings()

# Criar diretório de downloads se não existir
os.makedirs(Settings().DOWNLOAD_DIR, exist_ok=True)
