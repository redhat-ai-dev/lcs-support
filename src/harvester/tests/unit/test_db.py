# tests/unit/test_postgresdb.py
from unittest.mock import patch, MagicMock
from runner.utils.db import PostgresDB  # adjust import path

@patch("runner.utils.db.ConnectionPool")
def test_pool_creation_success(mock_connection_pool):
    mock_pool_instance = MagicMock()
    mock_connection_pool.return_value = mock_pool_instance

    db = PostgresDB()

    mock_connection_pool.assert_called_once()
    assert db.get_pool() == mock_pool_instance


@patch("runner.utils.db.ConnectionPool", side_effect=Exception("connection failed"))
def test_pool_creation_failure(mock_connection_pool):
    db = PostgresDB()
    assert db.get_pool() is None

@patch("runner.utils.db.ConnectionPool")
def test_execute_query(mock_connection_pool):
    mock_conn = MagicMock()
    mock_cursor = MagicMock()

    mock_pool = MagicMock()
    mock_pool.connection.return_value.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

    mock_connection_pool.return_value = mock_pool

    db = PostgresDB()
    data = ["data1", "data2", "data3"]
    db.execute("INSERT INTO test_table VALUES (%s, %s, %s)", data)

    mock_cursor.execute.assert_called_once_with("INSERT INTO test_table VALUES (%s, %s, %s)", data)
    mock_conn.commit.assert_called_once()
