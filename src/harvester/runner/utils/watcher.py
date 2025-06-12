import os
import logging
import time
import json
from typing import List
from runner.utils.db import PostgresDB
from runner.utils.utils import Feedback

def watch_directory(db: PostgresDB):
    directory_path = os.getenv("FEEDBACK_DIRECTORY", "/tmp/data/feedback")
    frequency = os.getenv("FETCH_FREQUENCY", 15*60) # 15 minutes

    while True:
        try:
            json_files = fetch_json_files(directory_path)
            current_file_count = len(json_files)
            if current_file_count > 0:
                logging.info(f"{current_file_count} file(s) in {directory_path}. Processing ...")

            process_json_files(json_files, directory_path, db)
            
        except Exception as e:
            logging.error(f"Error during processing: {e}")
        time.sleep(int(frequency))

def fetch_json_files(directory_path: str) -> List[str]:
    return [file for file in os.listdir(directory_path) if file.endswith('.json')]

def process_json_files(fetched_files: List[str], directory_path: str, db: PostgresDB) -> None:
    for filename in fetched_files:
        file_path = os.path.join(directory_path, filename)
        try:
            write_json_contents(file_path, db)
        except Exception as e:
            logging.error(f"Error reading {filename}: {e}")
        else:
            try:
                os.remove(file_path)
            except Exception as e:
                logging.error(f"Error deleting {filename}: {e}")

def write_json_contents(file_path: str, db: PostgresDB) -> None:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = json.load(f)
        feedback = Feedback(content)
        db.execute(feedback.get_query(), feedback.get_args())