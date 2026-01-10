import yt_dlp
from loguru import logger
import asyncio
import os
from ..core.config import get_settings
from ..core.config import get_settings
from .websocket_manager import manager
from yt_dlp.networking.impersonate import ImpersonateTarget

settings = get_settings()

class YtDlpService:
    @staticmethod
    def validate_integrity():
        """Verifica se o ambiente tem os requisitos mínimos (Node.js)"""
        try:
            import subprocess
            subprocess.check_call(["node", "--version"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except (OSError, subprocess.CalledProcessError):
            raise RuntimeError("Node.js não encontrado ou não executável. O backend não pode processar downloads sem um runtime JS válido.")

    @staticmethod
    def get_info(url: str):
        YtDlpService.validate_integrity()
        ydl_opts = {
            'quiet': True,
            'no_warnings': True,
            'impersonate': ImpersonateTarget(client='chrome'), # Simular navegador com objeto correto
            'js_runtimes': {'node': {}}, # Forçar Node.js
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            try:
                info = ydl.extract_info(url, download=False)
                
                # Extrair qualidades únicas (height)
                formats = info.get('formats', [])
                qualities = set()
                logger.info(f"Processando {len(formats)} formatos para {url}")
                
                for f in formats:
                    # Verificar se é vídeo (vcodec != none) e tem altura definida
                    height = f.get('height')
                    vcodec = f.get('vcodec')
                    
                    logger.info(f"Format: id={f.get('format_id')} height={height} vcodec={vcodec}")

                    if height and isinstance(height, int) and height > 0:
                         # Relaxed check: Accept if vcodec is missing (None) or not 'none' string
                         if vcodec is None or vcodec != 'none':
                            qualities.add(height)
                         else:
                            logger.info(f"Skipping format {f.get('format_id')} (vcodec='none')")
                
                logger.info(f"Qualidades encontradas: {qualities}")
                
                # Ordenar decrescente
                info['qualities'] = sorted(list(qualities), reverse=True)
                return info
            except Exception as e:
                logger.error(f"Erro ao obter info do vídeo: {e}")
                error_msg = str(e)
                if "Sign" in error_msg or "challenge" in error_msg or "bot" in error_msg.lower():
                    raise Exception("YouTube bloqueou o acesso (Signature/Challenge). Tente novamente em alguns minutos.")
                raise e

    @staticmethod
    async def download_video(url: str, client_id: str, quality: int = None):
        # Capturamos o loop atual (da thread principal onde o async roda)
        loop = asyncio.get_running_loop()
        
        # Pequeno delay para garantir que o frontend tenha tempo de conectar o WebSocket
        # Evita a condição de corrida onde o download começa antes de ter quem escute
        await asyncio.sleep(1.0) 

        def progress_hook(d):
            # Hook de progresso executado pelo yt-dlp (em thread separada)
            # logger.debug(f"Progress Hook Status: {d.get('status')}") # Debug opcional
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
            # REMOVIDO: elif d['status'] == 'finished': ...
            # Não enviamos 'finished' aqui porque o hook dispara para cada arquivo (video, audio) antes do merge.
            # O evento final será enviado apenas quando ydl.download() retornar.

        # Definir formato com base na qualidade
        # Requisito: Audio sempre da melhor qualidade possivel m4a (original), mesclado com qualidade de video desejada
        if quality:
            # STRICT MODE:
            format_str = f"bestvideo[height={quality}]+bestaudio[ext=m4a]/best[height={quality}]"
        else:
            format_str = f"{settings.YTDLP_FORMAT}" # Fallback para default

        # Verificar ambiente Node.js para debug
        try:
            import subprocess
            node_path = subprocess.check_output(["which", "node"]).decode().strip()
            node_version = subprocess.check_output(["node", "--version"]).decode().strip()
            logger.info(f"Ambiente JS: Node.js encontrado em '{node_path}' ({node_version})")
        except Exception as e:
            logger.warning(f"Ambiente JS: Erro ao detectar Node.js: {e}")

        # Configurar opções com runtime explícito
        ydl_opts = {
            'format': format_str,
            'outtmpl': f'{settings.DOWNLOAD_DIR}/%(title)s.%(ext)s',
            'progress_hooks': [progress_hook],
            'quiet': True,
            'merge_output_format': 'mp4', # Forçar merge para MP4
            'impersonate': ImpersonateTarget(client='chrome'), # Simular navegador com objeto correto
            # Forçar uso do Node.js como runtime JS (dict vazio ativa defaults)
            'js_runtimes': {'node': {}}, 
            'overwrites': True, # Sobrescrever para garantir download e eventos de progresso
        }

        # Rodar download em um thread separado
        try:
            filename = await loop.run_in_executor(None, lambda: _run_download(ydl_opts, url))
            
            # Se chegou aqui, download e merge (se houver) acabaram com sucesso
            logger.info(f"Download finalizado com sucesso: {filename}")
            await manager.send_personal_message({
                "status": "finished",
                "filename": os.path.basename(filename)
            }, client_id)
            
            return True
        except Exception as e:
            logger.error(f"Erro no download: {e}")
            await manager.send_personal_message({"status": "error", "message": str(e)}, client_id)
            return False

def _run_download(opts, url):
    with yt_dlp.YoutubeDL(opts) as ydl:
        # Extrair info primeiro para preparar o nome do arquivo final
        info = ydl.extract_info(url, download=False)
        filename = ydl.prepare_filename(info)
        
        # Ajustar extensão se houver merge forçado
        if opts.get('merge_output_format') == 'mp4':
            base, _ = os.path.splitext(filename)
            filename = f"{base}.mp4"
            
        ydl.download([url])
        return filename
