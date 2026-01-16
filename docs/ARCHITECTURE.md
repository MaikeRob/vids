# Arquitetura do Sistema

Este documento descreve a arquitetura técnica do projeto Vids.

## 🏛️ Visão Geral

O sistema é composto por uma API RESTful (Backend) que interage com o YouTube via `yt-dlp` e um aplicativo móvel (Frontend) que consome essa API e realiza processamento de mídia final.

```mermaid
graph TD
    User[Usuário Mobile] -->|Interage| App[Flutter App]
    App -->|HTTP Request /info| API[FastAPI Backend]
    App -->|HTTP Stream /stream| API
    API -->|Executa| YTDLP[yt-dlp Lib]
    YTDLP -->|Busca Dados| YouTube[YouTube Servers]
    API -->|Retorna Stream| App
    App -->|Processa (Merge/Convert)| FFmpeg[FFmpeg Kit Mobile]
    FFmpeg -->|Salva| Storage[Device Storage]
```

## 🔌 Backend (FastAPI)

O backend atua como um *proxy inteligente* e *adaptador* para o `yt-dlp`. Ele abstrai a complexidade de extração de links e streaming.

### Estrutura
- **`app/main.py`**: Ponto de entrada, configuração CORS e Middlewares.
- **`app/api/v1/endpoints/download.py`**: Rotas principais (`/info`, `/stream`).
- **`app/services/ytdlp_service.py`**: Wrapper em torno da biblioteca `yt-dlp`. Implementa lógica de melhor formato e streaming via pipe.
- **`app/schemas/`**: Modelos Pydantic para validação de entrada/saída.

### Decisões Chave
- **Streaming Direto**: O backend não salva arquivos em disco (exceto cache temporário do sistema operacional se necessário). Ele faz pipe do stdout do `yt-dlp` direto para a resposta HTTP (`StreamingResponse`). Isso economiza storage no servidor e reduz latência inicial.
- **UV**: Gerenciador de pacotes moderno para Python, garantindo instalações rápidas e ambientes isolados.

## 📱 Frontend (Flutter)

O aplicativo móvel é responsável pela UX, gerenciamento de download e pós-processamento (conversão).

### Estrutura
- **`lib/features/`**: Organização por feature (Clean Architecture simplificada).
    - **`download/`**: Lógica principal.
        - **`pages/`**: UI (HomePage).
        - **`providers/`**: Gerenciamento de estado (Riverpod). Lógica de negócios.
    - **`settings/`**: Configurações de conexão (IP/Porta) e Health Check.
- **`lib/shared/`**: Widgets e utilitários reutilizáveis.
- **`lib/core/`**: Temas e configurações globais.

### Fluxo de Dados (Riverpod)
1. User insere URL -> `HomePage` chama `Notifier`.
2. `Notifier` chama `API Client`.
3. `API Client` retorna metadados (JSON).
4. User seleciona qualidade/formato.
5. `Notifier` inicia download (Stream) salvando em cache temporário.
6. Se necessário (Audio/MP3), `Notifier` invoca `FFmpeg Kit` para conversão on-device.
7. Arquivo final movido para pasta pública (`Downloads/`).

### FFmpeg no Mobile
Optamos por usar `ffmpeg_kit_flutter_new_audio` para permitir conversão (MP4 -> MP3, Merge Video+Audio) no dispositivo do usuário. Isso distribui a carga de CPU e evita custos de processamento no servidor backend.
