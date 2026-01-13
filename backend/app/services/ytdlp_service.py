import yt_dlp
from loguru import logger
import asyncio
from yt_dlp.networking.impersonate import ImpersonateTarget

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
            'impersonate': ImpersonateTarget(client='chrome'),
            'js_runtimes': {'node': {}},
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            try:
                info = ydl.extract_info(url, download=False)

                formats = info.get('formats', [])
                # Use a dictionary to keep unique heights, keeping the best format for that height
                # Key: height, Value: {id, filesize, ...}
                unique_qualities = {}
                best_audio_size = 0

                logger.info(f"Processando {len(formats)} formatos para {url}")

                for f in formats:
                    height = f.get('height')
                    vcodec = f.get('vcodec')
                    acodec = f.get('acodec')
                    filesize = f.get('filesize') or f.get('filesize_approx') or 0
                    ext = f.get('ext')

                    # Logic for Video Qualities
                    if height and isinstance(height, int) and height > 0:
                         if vcodec is None or vcodec != 'none':
                            # Prefer format with filesize if available
                            current = unique_qualities.get(height)
                            # If we don't have this height yet, OR if the new one has a filesize (and existing didn't)
                            if not current or (filesize > 0 and current['filesize'] == 0):
                                unique_qualities[height] = {
                                    'height': height,
                                    'filesize': filesize,
                                    'format_id': f.get('format_id')
                                }

                    # Logic for Audio Size
                    # We look for 'audio only' formats (vcodec='none')
                    # We prioritize m4a since that's what we stream
                    if vcodec == 'none' and acodec != 'none' and filesize > 0:
                        if ext == 'm4a':
                             # Found m4a audio, update if it's larger (likely higher quality)
                             if filesize > best_audio_size:
                                 best_audio_size = filesize
                        elif best_audio_size == 0:
                             # If we haven't found any m4a yet, take this (e.g. webm) as a weak fallback estimate
                             best_audio_size = filesize

                # Convert to list and sort
                final_mx = []
                for h in sorted(unique_qualities.keys(), reverse=True):
                    final_mx.append(unique_qualities[h])

                info['qualities'] = final_mx
                info['audio_filesize'] = best_audio_size
                return info
            except Exception as e:
                logger.error(f"Erro ao obter info do vídeo: {e}")
                error_msg = str(e)
                if "Sign" in error_msg or "challenge" in error_msg or "bot" in error_msg.lower():
                    raise Exception("YouTube bloqueou o acesso. Tente novamente.")
                raise e

    @staticmethod
    async def stream_video(url: str, format_str: str):
        """Gera um stream de bytes diretamente do stdout do yt-dlp."""
        import sys

        cmd = [
            sys.executable, "-m", "yt_dlp",
            "--quiet", "--no-warnings",
            "-f", format_str,
            "-o", "-",
            url
        ]

        logger.info(f"Iniciando stream: {' '.join(cmd)}")

        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )

        try:
            while True:
                chunk = await process.stdout.read(64 * 1024)
                if not chunk:
                    break
                yield chunk

            await process.wait()

            if process.returncode != 0:
                stderr = await process.stderr.read()
                logger.error(f"Stream falhou: {stderr.decode()}")

        except Exception as e:
            logger.error(f"Erro durante stream: {e}")
            if process.returncode is None:
                process.terminate()
            raise e
