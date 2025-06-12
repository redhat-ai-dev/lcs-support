import logging
from runner.utils import utils
from runner.utils import db
from runner.utils import watcher

if __name__ == '__main__':

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s"
    )
    
    pg = db.PostgresDB()
    watcher.watch_directory(pg)