"""
MCP Oracle Read-Only Server
Servidor MCP para consultas de solo lectura a Oracle 19c.
Soporta modo thin (sin Oracle Client) y thick (con Instant Client).
Auto-configura certificados SSL para redes corporativas con proxy.

Para habilitar thick mode (necesario para algunas BDs como stage):
  1. Descargar Oracle Instant Client Basic Light para tu plataforma
  2. Configurar ORACLE_CLIENT_DIR con la ruta al directorio del client
     Ejemplo: ORACLE_CLIENT_DIR=/Users/usuario/Downloads/instantclient_23_26
  Si ORACLE_CLIENT_DIR no está configurado, usa thin mode automáticamente.
"""

# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "mcp>=1.0.0",
#     "oracledb>=2.0.0",
# ]
# ///

import os
import re
import sys
import json
import platform
import subprocess
import tempfile
from contextlib import contextmanager

import oracledb
from mcp.server.fastmcp import FastMCP


def setup_ssl_certs():
    """Configura certificados SSL del sistema para proxies corporativos."""
    if os.getenv("SSL_CERT_FILE"):
        return  # Ya configurado manualmente

    system = platform.system()
    if system == "Darwin":
        try:
            pem_path = os.path.join(tempfile.gettempdir(), "kiro-system-certs.pem")
            result = subprocess.run(
                ["security", "find-certificate", "-a", "-p",
                 "/System/Library/Keychains/SystemRootCertificates.keychain",
                 "/Library/Keychains/System.keychain"],
                capture_output=True, text=True, timeout=10,
            )
            if result.returncode == 0 and result.stdout.strip():
                with open(pem_path, "w") as f:
                    f.write(result.stdout)
                os.environ["SSL_CERT_FILE"] = pem_path
        except Exception:
            pass  # Si falla, continuar sin certs custom
    # Windows: uv usa certs del sistema por defecto, no necesita nada
    # Linux: usa /etc/ssl/certs por defecto


setup_ssl_certs()

# ---------------------------------------------------------------------------
# Thick mode (necesario para BDs con password verifier no soportado en thin)
# ---------------------------------------------------------------------------
ORACLE_CLIENT_DIR = os.getenv("ORACLE_CLIENT_DIR", "")
THICK_MODE = False

if ORACLE_CLIENT_DIR:
    try:
        oracledb.init_oracle_client(lib_dir=ORACLE_CLIENT_DIR)
        THICK_MODE = True
    except Exception as e:
        print(f"[WARN] No se pudo inicializar thick mode: {e}", file=sys.stderr)
        print("[WARN] Continuando en thin mode...", file=sys.stderr)
else:
    # Intentar auto-detectar Instant Client en rutas comunes
    common_paths = []
    home = os.path.expanduser("~")
    if platform.system() == "Darwin":
        downloads = os.path.join(home, "Downloads")
        if os.path.isdir(downloads):
            common_paths = [
                os.path.join(downloads, d)
                for d in sorted(os.listdir(downloads), reverse=True)
                if d.startswith("instantclient_")
            ]
        common_paths += ["/opt/oracle/instantclient", "/usr/local/oracle/instantclient"]
    elif platform.system() == "Linux":
        common_paths = ["/opt/oracle/instantclient", "/usr/lib/oracle/client"]
    elif platform.system() == "Windows":
        common_paths = [r"C:\oracle\instantclient"]

    for path in common_paths:
        if os.path.isdir(path) and any(f.startswith("libclntsh") for f in os.listdir(path)):
            try:
                oracledb.init_oracle_client(lib_dir=path)
                THICK_MODE = True
                print(f"[INFO] Thick mode habilitado con: {path}", file=sys.stderr)
                break
            except Exception:
                continue

    if not THICK_MODE:
        print("[INFO] Usando thin mode (sin Oracle Instant Client)", file=sys.stderr)

# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------
ORACLE_HOST = os.getenv("ORACLE_HOST", "localhost")
ORACLE_PORT = int(os.getenv("ORACLE_PORT", "1521"))
ORACLE_SERVICE = os.getenv("ORACLE_SERVICE", "")
ORACLE_SID = os.getenv("ORACLE_SID", "")
ORACLE_USER = os.getenv("ORACLE_USER", "")
ORACLE_PASSWORD = os.getenv("ORACLE_PASSWORD", "")
MAX_ROWS = int(os.getenv("MAX_ROWS", "500"))

if ORACLE_SID:
    DSN = oracledb.makedsn(ORACLE_HOST, ORACLE_PORT, sid=ORACLE_SID)
elif ORACLE_SERVICE:
    DSN = oracledb.makedsn(ORACLE_HOST, ORACLE_PORT, service_name=ORACLE_SERVICE)
else:
    raise ValueError("Debes configurar ORACLE_SID o ORACLE_SERVICE")

# ---------------------------------------------------------------------------
# Validación de solo lectura
# ---------------------------------------------------------------------------
FORBIDDEN_PATTERN = re.compile(
    r"\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|MERGE|GRANT|REVOKE|"
    r"EXECUTE|CALL|EXEC|BEGIN|DECLARE|COMMIT|ROLLBACK|SAVEPOINT)\b",
    re.IGNORECASE,
)


def validate_readonly(sql: str) -> None:
    stripped = sql.strip().rstrip(";")
    cleaned = re.sub(r"--.*$", "", stripped, flags=re.MULTILINE)
    cleaned = re.sub(r"/\*.*?\*/", "", cleaned, flags=re.DOTALL)
    cleaned = cleaned.strip()
    if not cleaned.upper().startswith("SELECT") and not cleaned.upper().startswith("WITH"):
        raise ValueError("Solo se permiten consultas SELECT o WITH (CTEs).")
    if FORBIDDEN_PATTERN.search(cleaned):
        raise ValueError("La consulta contiene operaciones prohibidas. Solo lectura (SELECT).")


@contextmanager
def get_connection():
    conn = oracledb.connect(user=ORACLE_USER, password=ORACLE_PASSWORD, dsn=DSN, tcp_connect_timeout=10)
    with conn.cursor() as cur:
        cur.execute("SET TRANSACTION READ ONLY")
    try:
        yield conn
    finally:
        conn.close()


def rows_to_dicts(cursor) -> list[dict]:
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchmany(MAX_ROWS)]


# ---------------------------------------------------------------------------
# Servidor MCP
# ---------------------------------------------------------------------------
mcp = FastMCP("oracle-readonly")


@mcp.tool()
def query(sql: str) -> str:
    """
    Ejecuta una consulta SELECT de solo lectura contra Oracle.
    Devuelve hasta 500 filas en formato JSON.

    Args:
        sql: Consulta SQL (solo SELECT o WITH/CTE permitidos)
    """
    validate_readonly(sql)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
            return json.dumps(rows_to_dicts(cur), default=str, ensure_ascii=False, indent=2)


@mcp.tool()
def list_tables(schema: str = "") -> str:
    """
    Lista las tablas de un esquema. Si no se indica esquema, usa el del usuario conectado.

    Args:
        schema: Nombre del esquema (opcional, por defecto el usuario actual)
    """
    owner = schema.upper() if schema else ORACLE_USER.upper()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT table_name, num_rows, last_analyzed FROM all_tables "
                "WHERE owner = :owner ORDER BY table_name",
                {"owner": owner},
            )
            return json.dumps(rows_to_dicts(cur), default=str, ensure_ascii=False, indent=2)


@mcp.tool()
def describe_table(table_name: str, schema: str = "") -> str:
    """
    Describe las columnas de una tabla: nombre, tipo de dato, si es nullable, etc.

    Args:
        table_name: Nombre de la tabla
        schema: Nombre del esquema (opcional, por defecto el usuario actual)
    """
    owner = schema.upper() if schema else ORACLE_USER.upper()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT column_name, data_type, data_length, data_precision, "
                "data_scale, nullable, column_id FROM all_tab_columns "
                "WHERE owner = :owner AND table_name = :table_name ORDER BY column_id",
                {"owner": owner, "table_name": table_name.upper()},
            )
            results = rows_to_dicts(cur)
    if not results:
        return json.dumps({"error": f"Tabla '{table_name}' no encontrada en esquema '{owner}'"})
    return json.dumps(results, default=str, ensure_ascii=False, indent=2)


@mcp.tool()
def list_schemas() -> str:
    """Lista los esquemas (usuarios) disponibles en la base de datos."""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT username AS schema_name, created FROM all_users ORDER BY username")
            return json.dumps(rows_to_dicts(cur), default=str, ensure_ascii=False, indent=2)


@mcp.tool()
def get_source(object_name: str, object_type: str = "PACKAGE BODY", schema: str = "") -> str:
    """
    Lee el código fuente de un objeto PL/SQL (package, procedure, function, trigger).

    Args:
        object_name: Nombre del objeto (ej: SIM_PCK_DEUDA)
        object_type: Tipo: PACKAGE, PACKAGE BODY, PROCEDURE, FUNCTION, TRIGGER
        schema: Esquema (por defecto OPS$PUMA)
    """
    owner = schema.upper() if schema else "OPS$PUMA"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "SELECT line, text FROM all_source "
                "WHERE owner = :owner AND name = :name AND type = :type "
                "ORDER BY line",
                {"owner": owner, "name": object_name.upper(), "type": object_type.upper()},
            )
            rows = cur.fetchall()
    if not rows:
        return json.dumps({"error": f"No se encontró {object_type} '{object_name}' en esquema '{owner}'"})
    source = "".join(row[1] for row in rows)
    return source


@mcp.tool()
def search_objects(pattern: str, schema: str = "", object_type: str = "") -> str:
    """
    Busca objetos por nombre parcial en la base de datos.

    Args:
        pattern: Patrón de búsqueda (se usa LIKE %pattern%)
        schema: Esquema (por defecto OPS$PUMA)
        object_type: Filtrar por tipo (PACKAGE, PROCEDURE, FUNCTION, TABLE, TRIGGER, VIEW). Vacío = todos.
    """
    owner = schema.upper() if schema else "OPS$PUMA"
    sql = (
        "SELECT object_name, object_type, status, last_ddl_time "
        "FROM all_objects WHERE owner = :owner AND object_name LIKE :pattern"
    )
    params: dict = {"owner": owner, "pattern": f"%{pattern.upper()}%"}
    if object_type:
        sql += " AND object_type = :otype"
        params["otype"] = object_type.upper()
    sql += " ORDER BY object_type, object_name"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql, params)
            return json.dumps(rows_to_dicts(cur), default=str, ensure_ascii=False, indent=2)


@mcp.tool()
def get_dependencies(object_name: str, schema: str = "", direction: str = "both") -> str:
    """
    Obtiene las dependencias de un objeto: quién lo usa (references) y a quién usa (referenced_by).

    Args:
        object_name: Nombre del objeto
        schema: Esquema (por defecto OPS$PUMA)
        direction: 'uses' (qué usa este objeto), 'used_by' (quién usa este objeto), 'both'
    """
    owner = schema.upper() if schema else "OPS$PUMA"
    result = {}
    with get_connection() as conn:
        with conn.cursor() as cur:
            if direction in ("uses", "both"):
                cur.execute(
                    "SELECT referenced_owner, referenced_name, referenced_type "
                    "FROM all_dependencies "
                    "WHERE owner = :owner AND name = :name "
                    "ORDER BY referenced_type, referenced_name",
                    {"owner": owner, "name": object_name.upper()},
                )
                result["uses"] = rows_to_dicts(cur)
            if direction in ("used_by", "both"):
                cur.execute(
                    "SELECT owner, name, type "
                    "FROM all_dependencies "
                    "WHERE referenced_owner = :owner AND referenced_name = :name "
                    "ORDER BY type, name",
                    {"owner": owner, "name": object_name.upper()},
                )
                result["used_by"] = rows_to_dicts(cur)
    return json.dumps(result, default=str, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    mcp.run()
