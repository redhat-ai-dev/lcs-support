import pytest
from runner.utils.utils import Feedback

test_res_base = "The following values are missing from the query response:"

@pytest.mark.parametrize("request_data, expected_exception, description", [
    (
        {
            "timestamp": "test-timestamp",
            "conversation_id": "test-convo-id",
            "user_question": "test-question",
            "llm_response": "test-llm-response"
        },
        f"{test_res_base} user_id",
        "missing-user-id"
    ),
    (
        {
            "user_id": "test-id",
            "conversation_id": "test-convo-id",
            "user_question": "test-question",
            "llm_response": "test-llm-response"
        },
        f"{test_res_base} timestamp",
        "missing-timestamp"
    ),
    (
        {
            "user_id": "test-id",
            "timestamp": "test-timestamp",
            "user_question": "test-question",
            "llm_response": "test-llm-response"
        },
        f"{test_res_base} conversation_id",
        "missing-convo-id"
    ),
    (
        {
            "user_id": "test-id",
            "timestamp": "test-timestamp",
            "conversation_id": "test-convo-id",
            "llm_response": "test-llm-response"
        },
        f"{test_res_base} user_question",
        "missing-user-question"
    ),
    (
        {
            "user_id": "test-id",
            "timestamp": "test-timestamp",
            "conversation_id": "test-convo-id",
            "user_question": "test-question"
        },
        f"{test_res_base} llm_response",
        "missing-llm-response"
    ),
    (
        {
            "sentiment": 1
        },
        f"{test_res_base} user_id, timestamp, conversation_id, user_question, llm_response",
        "missing-all-required"
    )
], 
ids=["missing-user-id", "missing-timestamp", "missing-convo-id", "missing-user-question", "missing-llm-response", "missing-all-required"])
def test_validate(request_data, expected_exception, description):
    with pytest.raises(Exception) as e:
        feedback = Feedback(request_data)
    assert expected_exception in str(e.value)