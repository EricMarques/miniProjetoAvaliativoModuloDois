"""
config.py
---------
Centraliza TODAS as configuracoes do pipeline:
  - leitura das credenciais do MySQL (a partir do arquivo .env)
  - parametros do que vamos baixar/processar (ID do arquivo no Drive)
  - nomes dos arquivos e das tabelas

Assim nenhuma senha fica escrita no codigo (boa pratica de seguranca).
"""

import os
from pathlib import Path
from dotenv import load_dotenv

# ---------------------------------------------------------------------------
# Caminhos do projeto
# ---------------------------------------------------------------------------
# PASTA_RAIZ = .../treino_cafeteria (a pasta deste arquivo)
PASTA_RAIZ = Path(__file__).resolve().parent
PASTA_DADOS = PASTA_RAIZ / "data"   # onde o .zip e os .csv ficam (ignorada pelo Git)


# ---------------------------------------------------------------------------
# Leitura simples do arquivo .env (sem biblioteca externa)
# ---------------------------------------------------------------------------
def carregar_env():
    """Le o arquivo .env (se existir) e joga as variaveis para os.environ."""
    arquivo_env = PASTA_RAIZ / ".env"
    if not arquivo_env.exists():
        return
    for linha in arquivo_env.read_text(encoding="utf-8").splitlines():
        linha = linha.strip()
        # ignora linhas vazias e comentarios
        if not linha or linha.startswith("#") or "=" not in linha:
            continue
        chave, valor = linha.split("=", 1)
        os.environ.setdefault(chave.strip(), valor.strip())


carregar_env()

load_dotenv()

# ---------------------------------------------------------------------------
# Credenciais do MySQL (armazenadas no arquivo .env)
# ---------------------------------------------------------------------------
MYSQL_CONFIG = {
    "host": os.getenv("HOST"),
    "port": os.getenv("PORT"),
    "user": os.getenv("USER"),
    "password": os.getenv("PASSWORD"),
    "database": os.getenv("DB"),
    "ssl_disabled": True,
}

# ---------------------------------------------------------------------------
# O que vamos baixar e processar
# ---------------------------------------------------------------------------


# ---- De onde baixar o .zip ----
DRIVE_FILE_ID = "1Sru-TYSYo-cn-L9WW2DUwhyIUdkM3fIe"

# Tamanho do bloco de leitura/insercao (numero de linhas por vez).

TAMANHO_BLOCO = 10_000

# Caracteristicas dos arquivos CSV do Portal da Transparencia:
CSV_SEPARADOR = ";"
CSV_ENCODING = "latin-1"   # acentuacao no padrao ISO-8859-1