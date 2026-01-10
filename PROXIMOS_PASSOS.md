# Guia de Preparação para Teste Mobile (APK)

O projeto está estável e funcional no emulador. Para testar em um dispositivo Android físico, siga os passos abaixo para configurar a rede, compilar o APK e instalar.

## 1. Configuração de Rede (Conectividade)

Como o celular e o computador estão em dispositivos separados, o `localhost` (ou `10.0.2.2`) do código não funcionará no celular. Eles precisam estar na mesma rede Wi-Fi.

### Passo 1: Descobrir seu IP Local
No terminal do Linux, execute:
```bash
hostname -I
```
Anote o primeiro IP retornado (ex: `192.168.1.15`).

### Passo 2: Atualizar o Frontend
Abra o arquivo `frontend/lib/features/download/data/datasources/download_api_client.dart`.
Altere as constantes `_baseUrl` e `_wsUrl` e o método `downloadFile` para usar seu IP real em vez de `10.0.2.2`.

```dart
// Exemplo (Substitua 192.168.X.X pelo seu IP)
static const String _baseUrl = 'http://192.168.1.15:8000/api/v1/download';
static const String _wsUrl = 'ws://192.168.1.15:8000/api/v1/download/ws';

// ... dentro de downloadFile ...
final downloadUrl = 'http://192.168.1.15:8000/api/v1/download/file/$filename';
```

### Passo 3: Liberar Firewall (Se necessário)
Certifique-se de que a porta `8000` do seu computador esteja acessível na rede local.
Se usar `ufw`:
```bash
sudo ufw allow 8000/tcp
```

---

## 2. Compilar o APK

Com o código atualizado, vá para a pasta do frontend e compile:

```bash
cd frontend
flutter build apk --release
```

O arquivo gerado estará em:
`frontend/build/app/outputs/flutter-apk/app-release.apk`

---

## 3. Instalar e Testar

### Opção A: Via Cabo (ADB)
Com o celular conectado e Depuração USB ativa:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Opção B: Transferência de Arquivo
Envie o arquivo `app-release.apk` para o celular (via USB, Drive, Telegram, etc.) e instale manualmente (pode ser necessário autorizar "Fontes Desconhecidas").

---

## ✅ Resumo do Status Atual (O que Testar)
1.  **Download**: Testar se o download inicia e termina.
2.  **Progresso**: Verificar se a barra e porcentagem atualizam no celular.
3.  **Reprodução**: Verificar se o vídeo baixado toca com áudio e vídeo sincronizados na galeria do celular.
4.  **Auto-Delete**: Verificar se o download funciona sem erros de "Arquivo não encontrado" (validando o novo endpoint).

## 🛠️ Comandos Úteis
Rebuildar Backend (se mudar algo no Python):
```bash
sudo docker compose up --build -d backend
```
Verificar logs do Backend (se o app der erro de conexão):
```bash
sudo docker logs -f vids-backend-1
```
