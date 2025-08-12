from typing import List

class Feedback():
    def __init__(self, data: dict):
        self.user_id = data.get("user_id")
        self.timestamp = data.get("timestamp")
        self.conversation_id = data.get("conversation_id")
        self.user_question = data.get("user_question")
        self.llm_response = data.get("llm_response")
        self.sentiment = data.get("sentiment")
        self.user_feedback = data.get("user_feedback")
        self.categories = data.get("categories")

        self._validate()

    def _validate(self) -> None:
        if not self.user_id \
        or not self.timestamp \
        or not self.conversation_id \
        or not self.user_question \
        or not self.llm_response:
            raise Exception("Values missing from query response.") #TODO: add better logging
        
    def get_args(self) -> List[str | None]:
        return [
            self.user_id,
            self.timestamp,
            self.conversation_id,
            self.user_question,
            self.llm_response,
            self.sentiment,
            self.user_feedback,
            self.categories
        ]
    
    def get_query(self) -> str:
        return "INSERT INTO feedback (user_id, timestamp, conversation_id, user_question, llm_response, sentiment, user_feedback, categories) VALUES (%s, %s, %s, %s, %s, %s, %s, %s);"