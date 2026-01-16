# Próximos Passos

## O que já temos (Status Atual)
- **Backend**: FastAPI + yt-dlp sem código morto (Limpeza realizada).
- **Frontend**:
    - App Flutter com design Glassmorphism "Premium".
    - **Health Check**: Tela de configurações com teste de conexão em tempo real.
    - **Áudio**: Suporte a download de M4A e conversão MP3 com FFmpeg.
    - **Docs**: Documentação completa em `docs/`.
    - **UI**: Ícone Full Bleed e remoção de marcas do YouTube.

## O que precisamos fazer (Next Steps)

### 1. Gerenciador de Downloads (Nova Feature Principal)
Estamos evoluindo o app para ter um gerenciamento robusto de fila.
- **[ ] Aba "Downloads"**:
    - Criar uma nova `BottomNavigationBar` ou aba para separar "Pesquisa" de "Meus Downloads".
    - Listar downloads em andamento e concluídos.
- **[ ] Background Execution**:
    - Os downloads não podem parar se o usuário minimizar o app.
    - Implementar `Isolates` ou serviços de background (ex: `flutter_background_service` ou `workmanager`).
- **[ ] Notificações**:
    - Mostrar notificação nativa com barra de progresso durante o download/conversão.
    - Notificação de "Concluído" ao finalizar.
