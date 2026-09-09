"""
conexao.py
-----------
Camada de conexão com o MySQL para o Dia 2.

Nos exercícios, importe a função `conectar`:

    from conexao import conectar

    conn = conectar()
    ...

Rodando este arquivo diretamente (python conexao.py) ele faz um teste:
conecta, imprime a versão do servidor e fecha a conexão.
"""

import mysql.connector
from mysql.connector import Error

from config.config import MYSQL_CONFIG


def conectar():
    """Abre e devolve uma conexão com o banco de logística.

    Lança mysql.connector.Error se a conexão falhar (deixe quem chamou
    decidir como tratar — aqui não engolimos o erro).
    """
    return mysql.connector.connect(**MYSQL_CONFIG)

def fechar_conexao():
    conn = conectar()
    if conn is not None and conn.is_connected():
        conn.close()
        print("Conexao encerrada.")

def abrir_conexao():
    """Conecta, imprime a versão do MySQL."""
    try:
        conn = conectar()
        cursor = conn.cursor()
        cursor.execute("SELECT VERSION()")
        (versao,) = cursor.fetchone()
        print(f"Conexao OK -> MySQL {versao}")
        cursor.close()
    except Error as erro:
        print("Falha na conexao:", erro)




def testar_conexao():
    """Conecta, imprime a versão do MySQL e encerra tudo com segurança."""
    conn = None
    try:
        abrir_conexao()
    finally:
        # finally roda SEMPRE: com sucesso ou com erro.
        fechar_conexao()

if __name__ == "__main__":
    testar_conexao()