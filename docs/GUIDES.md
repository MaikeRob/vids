# Guias e Tutoriais

## 🔧 Configuração e Instalação

### Pré-requisitos
- Docker Engine & Docker Compose
- Flutter SDK (Latest Stable)
- Android Studio / VS Code (com extensões Flutter/Dart)
- Dispositivo Android (ou Emulador)

### Health Check da API
O app possui um sistema de Health Check na tela de configurações.
1. Vá em Configurações (ícone de engrenagem).
2. Configure IP e Porta (Padrão Emulator: `10.0.2.2:8000`, Físico: `SEU_IP_LOCAL:8000`).
3. O ícone indicará se a conexão foi bem sucedida.

---

## 🚀 Build e Deploy (Android)

### 1. Ajustar Ícones
Se trocar a imagem do ícone:
```bash
cd frontend
# Coloque novo icone em assets/icon/app_icon.png
dart run flutter_launcher_icons
```

### 2. Gerar APK de Debug (Para Testes Físicos)
Este APK serve para instalar via cabo USB e testar performance real.
```bash
cd frontend
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

---

## 🧪 Testes

### Backend
```bash
cd backend
# Rodar testes unitários + cobertura
uv run pytest --cov=app
```
**Teste de API Externa**:
Use o script `external_tests/test_api_external.py` para validar o fluxo real de download do backend.

### Frontend
```bash
cd frontend
# Rodar testes de widget/unitários
flutter test
```

---

## ❓ Resolução de Problemas Comuns

### "Connection Refused" no Android
- **Causa**: O emulador não vê `localhost` como o PC.
- **Solução**: Use `10.0.2.2` no emulador. Em dispositivo físico, use o IP da LAN do seu PC (ex: `192.168.1.5`) e garanta que o firewall permite porta 8000.

### FFmpeg Falhando
- **Causa**: Arquitetura incompatível ou falta de codec.
- **Solução**: Estamos usando pacote `audio` que inclui `libmp3lame`. Se falhar, verifique logs com `flutter run` para ver a saída do FFmpeg. O diretório de trabalho do FFmpeg no Android 10+ (`Scoped Storage`) é restrito; usamos caminhos absolutos do `path_provider`.
