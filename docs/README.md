# Documentação do Projeto Vids

Bem-vindo à documentação oficial do projeto **Vids**. Este é o ponto de partida para entender, manter e contribuir com o projeto.

## 📚 Índice

| Documento | Descrição |
| :--- | :--- |
| **[Arquitetura](ARCHITECTURE.md)** | Visão geral do sistema, tecnologias, diagramas e estrutura de pastas. |
| **[Guias & Tutoriais](GUIDES.md)** | Como rodar, deploy, resolução de problemas e testes. |
| **[Padrões de Projeto](../AGENTS.md)** | Diretrizes de código, commit, segurança e regras do time (Agentic definition). |

## 🚀 Quick Start

Para rodar o projeto localmente em modo de desenvolvimento:

### 1. Backend (FastAPI)
```bash
cd backend
docker compose up --build
# API disponível em: http://localhost:8000
# Documentação Swagger Auto-gerada: http://localhost:8000/docs
```

### 2. Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
# Selecione seu dispositivo (Emulador ou Físico)
```

## 🛠️ Tecnologias Principais

- **Backend**: FastAPI (Python), Docker, yt-dlp, UV (Package Manager).
- **Frontend**: Flutter (Dart), Riverpod (State), Dio (HTTP), FFmpeg Kit (Conversão).

## 📄 Licença
Este projeto é para fins educacionais.
