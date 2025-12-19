import yt_dlp
from loguru import logger
import asyncio
from ..core.config import get_settings
from .websocket_manager import manager

settings = get_settings()

class YtDlpService:
    @staticmethod
    def get_info(url: str):
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            try:
                info = ydl.extract_info(url, download=False)
                return info
            except Exception as e:
                logger.error(f"Erro ao obter info do vídeo: {e}")
                raise e

    @staticmethod
    async def download_video(url: str, client_id: str):
        # Capturamos o loop atual (da thread principal onde o async roda)
        loop = asyncio.get_running_loop()

        def progress_hook(d):
            logger.info(f"Progress Hook Status: {d.get('status')}")
            if d['status'] == 'downloading':
                # Calcular porcentagem e velocidade
                total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                downloaded_bytes = d.get('downloaded_bytes', 0)
                speed = d.get('speed', 0)

                percentage = 0
                if total_bytes > 0:
                    percentage = (downloaded_bytes / total_bytes) * 100

                # CRITICAL FIX: Usamos o 'loop' capturado anteriormente, não get_event_loop()
                # pois esta função roda em uma thread worker separada (Executor) sem loop.
                asyncio.run_coroutine_threadsafe(
                    manager.send_personal_message({
                        "status": "downloading",
                        "percentage": percentage,
                        "speed": speed,
                        "filename": d.get('filename'),
                        "eta": d.get('eta')
                    }, client_id),
                    loop
                )
            elif d['status'] == 'finished':
                asyncio.run_coroutine_threadsafe(
                    manager.send_personal_message({
                        "status": "finished",
                        "filename": d.get('filename')
                    }, client_id),
                    loop
                )

        ydl_opts = {
            'format': settings.YTDLP_FORMAT,
            'outtmpl': f'{settings.DOWNLOAD_DIR}/%(title)s.%(ext)s',
            'progress_hooks': [progress_hook],
            'quiet': True,
        }

        # Rodar download em um thread separado (Executor) para não bloquear o event loop principal
        try:
            # Passamos o '_run_download' para o executor
            await loop.run_in_executor(None, lambda: _run_download(ydl_opts, url))
            return True
        except Exception as e:
            logger.error(f"Erro no download: {e}")
            await manager.send_personal_message({"status": "error", "message": str(e)}, client_id)
            return False

def _run_download(opts, url):
    with yt_dlp.YoutubeDL(opts) as ydl:
        ydl.download([url])
