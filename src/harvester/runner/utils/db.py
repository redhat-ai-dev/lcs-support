import os
import logging
from psycopg_pool import ConnectionPool

class PostgresDB():
    def __init__(self):
        self.user = os.getenv("PGUSER", "postgres")
        self.password = os.getenv("PGPASSWORD", "password")
        self.host = os.getenv("PGHOST", "localhost")
        self.dbname = os.getenv("PGDATABASE", "postgres")
        self.port = os.getenv("PGPORT", "5432")
        self.pool = self._create_pool()
    
    def _get_connection_str(self) -> str:
        return (
            f"postgresql://{self.user}:{self.password}@{self.host}:{self.port}/{self.dbname}"
        )
    
    def _create_pool(self) -> ConnectionPool | None:
        result = None
        try:
            result = ConnectionPool(conninfo=self._get_connection_str(), min_size=1, max_size=5)
            logging.info(f"Successfully created Postgres pool connection")
        except Exception as e:
            logging.error(f"Failed to create connection pool: {e}")
        return result
    
    def execute(self, query: str, params: list) -> None:
        """Execute a query (e.g., INSERT/UPDATE)."""
        try:
            with self.pool.connection() as conn:
                with conn.cursor() as cur:
                    cur.execute(query, params)
                    conn.commit()
        except Exception as e:
            logging.error(f"Error executing query to PostgreSQL database: {e}")
    
    def get_pool(self) -> ConnectionPool | None:
        return self.pool