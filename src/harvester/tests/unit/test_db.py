import pytest
from runner.utils.utils import Feedback
from unittest.mock import patch, MagicMock
from runner.utils.db import PostgresDB

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

@pytest.mark.parametrize("feedback_data,expected_categories,test_description", [
    ({
        "user_id": "test-user-123",
        "timestamp": "2025-01-15 10:30:00.123456",
        "conversation_id": "conv-456",
        "user_question": "Test question 1",
        "llm_response": "Test response 1",
        "user_feedback": "Test feedback 1",
        "categories": ["deployment", "kubernetes"]
    }, ["deployment", "kubernetes"], "sentiment_missing"),
    ({
        "user_id": "test-user-456",
        "timestamp": "2025-01-15 11:30:00.123456",
        "conversation_id": "conv-789",
        "user_question": "Test question 2",
        "llm_response": "Test response 2",
        "sentiment": 1,
        "categories": ["general", "tutorial"]
    }, ["general", "tutorial"], "user_feedback_missing"),
    ({
        "user_id": "test-user-789",
        "timestamp": "2025-01-15 12:30:00.123456",
        "conversation_id": "conv-abc",
        "user_question": "Test question 3",
        "llm_response": "Test response 3",
        "sentiment": 1,
        "user_feedback": "Test feedback 3"
    }, None, "categories_missing"),
    ({
        "user_id": "test-user-000",
        "timestamp": "2025-01-15 13:30:00.123456",
        "conversation_id": "conv-def",
        "user_question": "Test question 4",
        "llm_response": "Test response 4",
        "sentiment": -1,
        "user_feedback": "Test feedback 4",
        "categories": []
    }, [], "empty_categories_array"),
    ({
        "user_id": "test-user-111",
        "timestamp": "2025-01-15 14:30:00.123456",
        "conversation_id": "conv-ghi",
        "user_question": "Test question 5",
        "llm_response": "Test response 5",
        "sentiment": -1,
        "user_feedback": "Test feedback 5",
        "categories": ["incomplete"]
    }, ["incomplete"], "single_category"),
    ({
        "user_id": "test-user-222",
        "timestamp": "2025-01-15 15:30:00.123456",
        "conversation_id": "conv-jkl",
        "user_question": "Test question 6",
        "llm_response": "Test response 6",
        "sentiment": -1,
        "user_feedback": "Test feedback 6",
        "categories": ["incorrect", "not_relevant", "other"]
    }, ["incorrect", "not_relevant", "other"], "three_specific_categories")
], ids=["sentiment_missing", "user_feedback_missing", "categories_missing", "empty_categories_array", "single_category", "three_specific_categories"])

@patch("runner.utils.db.ConnectionPool")
def test_feedback_insertion_with_categories_scenarios(mock_connection_pool, feedback_data, expected_categories, test_description):
    mock_conn = MagicMock()
    mock_cursor = MagicMock()

    mock_pool = MagicMock()
    mock_pool.connection.return_value.__enter__.return_value = mock_conn
    mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

    mock_connection_pool.return_value = mock_pool

    db = PostgresDB()
    feedback = Feedback(feedback_data)
    db.execute(feedback.get_query(), feedback.get_args())

    expected_query = "INSERT INTO feedback (user_id, timestamp, conversation_id, user_question, llm_response, sentiment, user_feedback, categories) VALUES (%s, %s, %s, %s, %s, %s, %s, %s);"
    
    # Verify the categories field in the args matches expected
    called_args = mock_cursor.execute.call_args[0][1]
    assert called_args[7] == expected_categories  # categories is the 8th argument (index 7)
    
    # Also verify sentiment and user_feedback are handled correctly for missing scenarios
    if "sentiment" not in feedback_data:
        assert called_args[5] is None  # sentiment should be None when missing
    if "user_feedback" not in feedback_data:
        assert called_args[6] is None  # user_feedback should be None when missing
    
    mock_cursor.execute.assert_called_once_with(expected_query, called_args)
    mock_conn.commit.assert_called_once()