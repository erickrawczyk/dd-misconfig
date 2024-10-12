import logging
import os
import threading
import time
from datetime import datetime

from flask import Flask

app = Flask(__name__)

# Create a logs directory if it doesn't exist
if not os.path.exists("/var/log/flask"):
    os.makedirs("/var/log/flask")

# Configure logging to a file with a custom format
logging.basicConfig(
    filename="/var/log/flask/flask.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


def log_periodically():
    while True:
        try:
            # Log a regular message
            app.logger.info(f"Logging a message every second: {datetime.now()}")
            # Intentionally cause a ZeroDivisionError every 10 seconds
            if int(time.time()) % 10 == 0:
                1 / 0
        except Exception as e:
            app.logger.exception("An error occurred")
        time.sleep(1)


@app.route("/")
def hello():
    return "Hello, World!"


if __name__ == "__main__":
    log_thread = threading.Thread(target=log_periodically)
    log_thread.daemon = True
    log_thread.start()
    app.run(host="0.0.0.0", port=80)
