import yt_dlp
import sys

def test_config(config_name, opts):
    print(f"--- Testando configuração: {config_name} ---")
    print(f"Opções: {opts}")
    try:
        with yt_dlp.YoutubeDL(opts) as ydl:
            print(">>> SUCESSO: Configuração aceita!")
    except Exception as e:
        print(f">>> ERRO: {e}")
    print("-" * 30 + "\n")

# Casos que sabemos que falham (removidos para limpar output)

# Caso que funcionou: 'path'
test_config("Dict com key 'path'", {'js_runtimes': {'node': {'path': 'node'}}})

# Teste: Dict Vazio (Pode usar default path?)
test_config("Dict Vazio {}", {'js_runtimes': {'node': {}}})

# Teste: Dict com 'args' (List)
test_config("Dict com key 'args' (List)", {'js_runtimes': {'node': {'args': ['node']}}})

# Teste: Dict com 'args' incorreto (String)
test_config("Dict com key 'args' (String - Falha esperada?)", {'js_runtimes': {'node': {'args': 'node'}}})
