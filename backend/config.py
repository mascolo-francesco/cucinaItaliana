import os
from urllib.parse import urlparse
from dotenv import load_dotenv

load_dotenv()

def _config_from_uri(uri: str) -> dict:
    parsed = urlparse(uri)
    if parsed.scheme not in {"mysql", "mysql+pymysql"}:
        raise ValueError("DB_URI deve iniziare con mysql://")
    return {
        "host": parsed.hostname or "localhost",
        "port": parsed.port or 3306,
        "user": parsed.username or "root",
        "password": parsed.password or "",
        "database": (parsed.path or "/cucina_italiana").lstrip("/"),
    }


DB_URI = os.getenv("DB_URI")
if DB_URI:
    DB_CONFIG = _config_from_uri(DB_URI)
else:
    DB_CONFIG = {
        "host": os.getenv("DB_HOST", "localhost"),
        "port": int(os.getenv("DB_PORT", "3306")),
        "user": os.getenv("DB_USER", "root"),
        "password": os.getenv("DB_PASSWORD", ""),
        "database": os.getenv("DB_NAME", "cucina_italiana"),
    }

SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key")
