# YouTube Downloader

App educacional para download de vídeos do YouTube.

## Stack
**Backend**: FastAPI + Python 3.12 + yt-dlp + uv  
**Frontend**: Flutter + Riverpod + Freezed  
**Design**: Dark mode (#0f0f23) + Glassmorphism + Gradients (#667eea→#764ba2)

## Comandos

### Backend
```bash
cd backend
uv venv && source .venv/bin/activate
uv pip install -e ".[dev]"
uv run uvicorn app.main:app --reload
uv run pytest --cov=app --cov-fail-under=85
uv run ruff check . && uv run mypy app
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
flutter test --coverage
flutter analyze
```

## Estrutura
```
backend/app/
  ├─ api/v1/          # Endpoints REST
  ├─ core/            # Config, logging, security
  ├─ models/          # Pydantic models
  └─ services/        # Business logic

frontend/lib/
  ├─ core/            # Theme, constants
  ├─ features/        # Clean Architecture (data, domain, presentation)
  └─ shared/          # Widgets compartilhados
```

## Do
- Use **type hints** sempre (Python) e **const** (Flutter)
- **Async/await** para I/O operations
- **Pydantic** para validação (backend)
- **Riverpod + Freezed** para state (frontend)
- **TDD**: escreva testes ANTES do código
- **Rate limiting** em endpoints públicos (`@limiter.limit("5/minute")`)
- **Structured logs**: `logger.info("message", key=value)`
- Widgets pequenos (<200 linhas)
- Commits: `feat(scope): description`

## Don't
- ❌ Sync operations em rotas async
- ❌ `print()` (use logger)
- ❌ Hard-coded colors/secrets
- ❌ StatefulWidget sem necessidade
- ❌ Código sem testes
- ❌ Commits direto em `main`

## Testes
- **Cobertura mínima**: Backend 85%, Frontend 80%
- **TDD obrigatório**: teste → código → refactor
- Rodar antes de commit: `pytest` + `flutter test`

## Segurança
- Validação de URLs (apenas youtube.com/youtu.be)
- Secrets em `.env` (nunca hard-coded)
- Rate limiting configurado
- Sem stack traces em produção

## PR Checklist
- [ ] Testes passando (>85% backend, >80% frontend)
- [ ] Linters sem erros (`ruff`, `mypy`, `flutter analyze`)
- [ ] Commit segue Conventional Commits
- [ ] Diff pequeno e focado

## Pedir Aprovação Antes
- Adicionar dependências >10MB
- Mudar schemas de banco
- Modificar CI/CD
- Alterar arquitetura principal

## Docs
- FastAPI: https://fastapi.tiangolo.com
- Flutter: https://docs.flutter.dev
- Riverpod: https://riverpod.dev
