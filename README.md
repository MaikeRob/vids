# YouTube Downloader

Aplicativo educacional para download de vídeos do YouTube.

## Tech Stack

- **Backend**: Python (FastAPI) + yt-dlp
- **Frontend**: Flutter (Mobile)

## Setup

### Pré-requisitos
- Docker & Docker Compose
- Flutter SDK (para desenvolvimento mobile)
- Python 3.12+ (opcional, se não usar Docker)

### Rodando o Backend (Docker)
```bash
docker compose up --build
```
A API estará disponível em: `http://localhost:8000`
Docs: `http://localhost:8000/docs`

### Rodando o Frontend (Mobile)
```bash
cd frontend
flutter pub get
flutter run
```

## Estrutura do Projeto
- `backend/`: API RESTful
- `frontend/`: Aplicativo Flutter

## 🧪 Como Testar

### Backend
1. Entre na pasta backend: `cd backend`
2. Instale dependências de desenvolvimento: `uv sync --dev`
3. Rode os testes:
```bash
uv run pytest
```

### Frontend
1. Entre na pasta frontend: `cd frontend`
2. Gere os mocks (se necessário):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
3. Rode os testes:
```bash
flutter test
```
