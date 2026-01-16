from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse
from ....services.ytdlp_service import YtDlpService
from ....schemas.video import VideoInfo, DownloadRequest, StreamRequest
from loguru import logger

router = APIRouter()

@router.post("/info", response_model=VideoInfo)
async def get_video_info(request: DownloadRequest):
    """
    Obtém metadados de um vídeo do YouTube.

    Recupera título, thumbnail, duração e lista de formatos disponíveis.
    """
    try:
        info = YtDlpService.get_info(request.url)
        return VideoInfo(
            title=info.get('title', 'Unknown'),
            thumbnail=info.get('thumbnail', ''),
            duration=info.get('duration', 0),
            uploader=info.get('uploader', 'Unknown'),
            view_count=info.get('view_count', 0),
            webpage_url=info.get('webpage_url', request.url),
            qualities=info.get('qualities', []),
            audio_filesize=info.get('audio_filesize', 0)
        )
    except Exception as e:
        logger.exception("Detalhes completos do erro:")
        logger.error(f"Erro ao obter info: {repr(e)}")
        raise HTTPException(status_code=400, detail=f"Falha ao obter vídeo: {str(e) or repr(e)}")

@router.post("/stream")
async def stream_media(request: StreamRequest):
    """
    Stream de mídia (video ou audio) direto do yt-dlp.
    Não salva nada no disco.
    """
    if request.mode == 'audio':
        format_str = "bestaudio[ext=m4a]"
        media_type = "audio/mp4"
        filename = "audio.m4a"
    else:
        # Video mode
        if request.quality:
            format_str = f"bestvideo[height={request.quality}]"
        else:
            format_str = "bestvideo"
        media_type = "video/mp4"
        filename = "video.mp4"

    return StreamingResponse(
        YtDlpService.stream_video(request.url, format_str),
        media_type=media_type,
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )
