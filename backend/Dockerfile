FROM python:3.12-slim

# Instalar ffmpeg (necessário para yt-dlp)
RUN apt-get update && apt-get install -y ffmpeg && rm -rf /var/lib/apt/lists/*

# Instalar Deno (Runtime JS recomendado para yt-dlp)
COPY --from=denoland/deno:bin /deno /usr/local/bin/deno

WORKDIR /app

# Instalar uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copiar arquivos de dependência
COPY pyproject.toml .

# Instalar dependências (sem --frozen para gerar lockfile na primeira vez)
RUN uv sync

# Copiar código fonte
COPY app ./app

# Expor porta
EXPOSE 8000

# Comando de execução
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
