import mysql.connector
from mysql.connector import pooling
from config import DB_CONFIG

_POOL = None


def get_pool():
    global _POOL
    if _POOL is None:
        _POOL = pooling.MySQLConnectionPool(
            pool_name="cucina_pool",
            pool_size=5,
            **DB_CONFIG,
        )
    return _POOL


def get_connection():
    return get_pool().get_connection()
