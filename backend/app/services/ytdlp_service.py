import yt_dlp
from loguru import logger
import asyncio
import os
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
                
                # Extrair qualidades únicas (height)
                formats = info.get('formats', [])
                qualities = set()
                logger.info(f"Processando {len(formats)} formatos para {url}")
                
                for f in formats:
                    # Verificar se tem altura definida (indicativo de stream de vídeo)
                    height = f.get('height')
                    if height and isinstance(height, int) and height > 0:
                        qualities.add(height)
                
                logger.info(f"Qualidades encontradas: {qualities}")
                
                # Ordenar decrescente
                info['qualities'] = sorted(list(qualities), reverse=True)
                return info
            except Exception as e:
                logger.error(f"Erro ao obter info do vídeo: {e}")
                raise e

    @staticmethod
    async def download_video(url: str, client_id: str, quality: int = None):
        # Capturamos o loop atual (da thread principal onde o async roda)
        loop = asyncio.get_running_loop()

        def progress_hook(d):
            # ... (código do hook mantido igual, mas omitido aqui para brevidade se não mudar)
            # COPIAR IMPLEMENTAÇÃO ORIGINAL DO HOOK AQUI PARA MANTER FUNCIONANDO
            logger.info(f"Progress Hook Status: {d.get('status')}")
            if d['status'] == 'downloading':
                total_bytes = d.get('total_bytes') or d.get('total_bytes_estimate', 0)
                downloaded_bytes = d.get('downloaded_bytes', 0)
                speed = d.get('speed', 0)

                percentage = 0
                if total_bytes > 0:
                    percentage = (downloaded_bytes / total_bytes) * 100

                asyncio.run_coroutine_threadsafe(
                    manager.send_personal_message({
                        "status": "downloading",
                        "percentage": percentage,
                        "speed": speed,
                        "filename": os.path.basename(d.get('filename', '')),
                        "eta": d.get('eta')
                    }, client_id),
                    loop
                )
            elif d['status'] == 'finished':
                asyncio.run_coroutine_threadsafe(
                    manager.send_personal_message({
                        "status": "finished",
                        "filename": os.path.basename(d.get('filename', ''))
                    }, client_id),
                    loop
                )

        # Definir formato com base na qualidade
        # Requisito: Audio sempre da melhor qualidade possivel m4a (original), mesclado com qualidade de video desejada
        if quality:
            # bestvideo[height<=Q]: Busca o melhor vídeo com altura até Q (garante a escolha do usuário pois filtramos antes)
            # bestaudio[ext=m4a]: Busca o melhor áudio m4a original disponível (sem transcodificação se possível)
            format_str = f"bestvideo[height<={quality}]+bestaudio[ext=m4a]/best[height<={quality}]"
        else:
            format_str = f"{settings.YTDLP_FORMAT}" # Fallback para default

        ydl_opts = {
            'format': format_str,
            'outtmpl': f'{settings.DOWNLOAD_DIR}/%(title)s.%(ext)s',
            'progress_hooks': [progress_hook],
            'quiet': True,
        }

        # Rodar download em um thread separado
        try:
            await loop.run_in_executor(None, lambda: _run_download(ydl_opts, url))
            return True
        except Exception as e:
            logger.error(f"Erro no download: {e}")
            await manager.send_personal_message({"status": "error", "message": str(e)}, client_id)
            return False

def _run_download(opts, url):
    with yt_dlp.YoutubeDL(opts) as ydl:
        ydl.download([url])
