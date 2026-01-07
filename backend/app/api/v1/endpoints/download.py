from fastapi import APIRouter, HTTPException, WebSocket, WebSocketDisconnect
from ....services.ytdlp_service import YtDlpService
from ....services.websocket_manager import manager
from ....schemas.video import VideoInfo, DownloadRequest, DownloadResponse
import uuid
import asyncio

router = APIRouter()

@router.post("/info", response_model=VideoInfo)
async def get_video_info(request: DownloadRequest):
    try:
        info = YtDlpService.get_info(request.url)
        return VideoInfo(
            title=info.get('title', 'Unknown'),
            thumbnail=info.get('thumbnail', ''),
            duration=info.get('duration', 0),
            uploader=info.get('uploader', 'Unknown'),
            view_count=info.get('view_count', 0),
            webpage_url=info.get('webpage_url', request.url),
            qualities=info.get('qualities', [])
        )
    except Exception as e:
        logger.error(f"Erro ao obter info: {e}")
        raise HTTPException(status_code=400, detail=f"Falha ao obter vídeo: {str(e)}")

@router.post("/start", response_model=DownloadResponse)
async def start_download(request: DownloadRequest):
    # Gerar um ID de tarefa (será usado como client_id no websocket no futuro)
    # Na implementação simplificada MVP, o cliente conecta no WS primeiro e envia o ID aqui,
    # OU geramos aqui e cliente conecta depois.
    # Vamos assumir que o cliente gera um UUID e passa, ou passamos aqui.
    # Melhor fluxo MVP: Cliente conecta WS com UUID gerado por ele. Cliente chama start com esse UUID.
    # Mas como o endpoint não recebe o UUID no request (no schema atual), vamos simplificar:
    # O schema DownloadRequest não tem ID. Vamos adicionar um header ou query param?
    # Vamos alterar o fluxo: Cliente chama esse endpoint, recebe um taskId.
    # Cliente conecta no WS com esse taskId.
    # Backend inicia download async usando esse taskId.

    task_id = str(uuid.uuid4())

    # Iniciar download em background (fire and forget)
    # Passamos quality se existir
    asyncio.create_task(YtDlpService.download_video(request.url, task_id, request.quality))

    return DownloadResponse(
        task_id=task_id,
        status="pending",
        message="Download iniciado em background. Conecte no WebSocket com o task_id para progresso."
    )

@router.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str):
    print(f"Tentativa de conexão WebSocket: {client_id}")
    await manager.connect(websocket, client_id)
    try:
        while True:
            # Manter conexão viva e ouvir (opcional receber comandos)
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(client_id)
