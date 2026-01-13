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
- ❌ Mudanças sem análise de impacto
- ❌ Correções "cegas" (sem pesquisa/análise prévia)

## Idioma
- **Respostas**: Sempre responda em **Português (PT-BR)**, mesmo que o código seja em inglês.

## Protocolo de Mudanças e Ações
- **Evidência Concreta**: NUNCA assuma que uma correção vai funcionar baseada em intuição.
    - Antes de adicionar dependências ou mudar configurações críticas, **pesquise na documentação oficial** ou fóruns confiáveis (StackOverflow, GitHub Issues).
    - Use a tool `search_web` para validar compatibilidade (ex: "yt-dlp impersonate dependencies docker python slim").
    - Se não houver evidência, crie um script de prova de conceito (POC) antes de alterar o código principal.

## Protocolo de Correção de Erros
1. **Análise Completa**: Antes de qualquer código, investigue a causa raiz.
2. **Pesquisa**: Busque problemas similares e soluções na internet/documentação.
3. **Relatório de Soluções**: Apresente um relatório com:
   - Causa identificada
   - Possíveis abordagens (A, B, C)
   - Prós e contras de cada uma
   - Recomendação
4. **Impacto e Efeitos Colaterais (CRÍTICO)**:
   - Analise consequências da mudança em todo o sistema.
   - Pense: "Se eu alterar X, o que acontece com Y?" (Ex: Importações, tipos, dependências de runtime).
   - Verifique se *todos* os símbolos usados foram importados. NÃO assuma.
5. **Aprovação**: Aguarde escolha do usuário.

## Testes (Obrigatório)
- **Testar TUDO**: Unitários, Integração e E2E quando possível.
- **Tipos de Teste**:
  - Unitários: Lógica isolada (backend services, frontend utils/providers)
  - Integração: APIs, Fluxos de UI, Conexão com serviços externos (mocks controlados)
  - Regressão: Garantir que o novo fix não quebrou o antigo.

- **TDD obrigatório**: teste → código → refactor
- Rodar antes de commit: `pytest` + `flutter test`

## Segurança
- Validação de URLs (apenas youtube.com/youtu.be)
- Secrets em `.env` (nunca hard-coded)
- Rate limiting configurado
- Sem stack traces em produção

## Pedir Aprovação Antes
- Adicionar dependências >10MB
- Mudar schemas de banco
- Modificar CI/CD
- Alterar arquitetura principal

## Docs
- FastAPI: https://fastapi.tiangolo.com
- Flutter: https://docs.flutter.dev
- Riverpod: https://riverpod.dev

## Frontend Progress Logic
O backend utiliza streaming para entregar o conteúdo (`/stream`), portanto não envia `Content-Length` na resposta.
Para calcular a porcentagem de download:
1. Obtenha o tamanho estimado (`filesize` ou `filesize_approx`) do endpoint `/info` para a qualidade escolhida.
2. Durante o download do stream, some os bytes recebidos.
3. `Progresso % = (Bytes Recebidos / Tamanho Estimado) * 100`.
