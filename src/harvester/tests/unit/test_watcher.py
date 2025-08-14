import os
import json
import pytest
from unittest.mock import patch, MagicMock, mock_open
from runner.utils.db import PostgresDB
from runner.utils.watcher import (
    fetch_json_files,
    process_json_files,
    write_json_contents,
)

@patch("runner.utils.watcher.os.listdir")
def test_fetch_json_files(mock_listdir):
    mock_listdir.return_value = ["a.json", "b.txt", "c.json"]

    result = fetch_json_files("/some/dir")

    assert result == ["a.json", "c.json"]
    mock_listdir.assert_called_once_with("/some/dir")

@patch("runner.utils.watcher.write_json_contents")
@patch("runner.utils.watcher.os.remove")
def test_process_json_files_success(mock_remove, mock_write):
    db = MagicMock(spec=PostgresDB)
    files = ["file1.json", "file2.json"]
    directory = "/test/dir"

    process_json_files(files, directory, db)

    expected_paths = [os.path.join(directory, f) for f in files]

    assert mock_write.call_count == 2
    mock_write.assert_any_call(expected_paths[0], db)
    mock_write.assert_any_call(expected_paths[1], db)

    assert mock_remove.call_count == 2
    mock_remove.assert_any_call(expected_paths[0])
    mock_remove.assert_any_call(expected_paths[1])


@patch("runner.utils.watcher.os.remove")
@patch("runner.utils.watcher.write_json_contents", side_effect=Exception("failure"))
@patch("runner.utils.watcher.logging.error")
def test_process_json_files_read_failure(mock_log, mock_write, mock_remove):
    db = MagicMock(spec=PostgresDB)
    files = ["broken.json"]
    directory = "/some/path"

    process_json_files(files, directory, db)

    mock_write.assert_called_once()
    mock_remove.assert_not_called()
    mock_log.assert_called_once_with("Error reading broken.json: failure")


@patch("runner.utils.watcher.write_json_contents")
@patch("runner.utils.watcher.os.remove", side_effect=Exception("delete failed"))
@patch("runner.utils.watcher.logging.error")
def test_process_json_files_delete_failure(mock_log, mock_remove, mock_write):
    db = MagicMock(spec=PostgresDB)
    files = ["file.json"]
    directory = "/some/path"

    process_json_files(files, directory, db)

    mock_write.assert_called_once()
    mock_remove.assert_called_once()
    mock_log.assert_called_once_with("Error deleting file.json: delete failed")

def test_write_json_contents():
    sample_files = [
        "sample_feedback_1.json",
        "sample_feedback_2.json",
        "sample_feedback_3.json"
    ]
    for file in sample_files:
        test_file_path = os.path.join(os.path.dirname(__file__), "data", file)
        mock_db = MagicMock()
        mock_fb_instance = MagicMock()
        mock_fb_instance.get_query.return_value = "INSERT INTO ..."
        mock_fb_instance.get_args.return_value = ("val",)
        
        write_json_contents(test_file_path, mock_db)

        mock_db.execute.assert_called_once()
