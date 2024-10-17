import logging
import os
import threading
import time
from datetime import datetime

import psycopg2
from datadog import initialize, statsd
from ddtrace import patch_all, tracer
from flask import Flask, jsonify

DB_HOST = "database"
DB_PORT = 5432
DB_NAME = "mydatabase"
DB_USER = "datadog"
DB_PASSWORD = "datadog"

patch_all()

app = Flask(__name__)

initialize(statsd_host="dd-agent", statsd_port=8125)

# Configure logging to a file with a custom format
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)


@app.errorhandler(Exception)
def handle_exception(e):
    app.logger.error("Unhandled exception occurred", exc_info=True)
    return jsonify({"error": "An internal error occurred", "message": str(e)}), 500


def get_db_connection():
    conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    return conn


def create_table():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS logs (
            id SERIAL PRIMARY KEY,
            message TEXT NOT NULL,
            created_at TIMESTAMP NOT NULL DEFAULT NOW()
        )
    """
    )
    conn.commit()
    cur.close()
    conn.close()


def create_log(message):
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO logs (message) VALUES (%s)", (message,))
    conn.commit()
    cur.close()
    conn.close()


def get_logs():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT * FROM logs")
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return rows


def log_periodically():
    while True:
        app.logger.info(f"Logging a message every second: {datetime.now()}")
        statsd.increment("misconfigbase.autolog_count", tags=["environment:development"])
        time.sleep(1)


def insert_periodically():
    while True:
        create_log(f"Record inserted at {datetime.now()}")
        time.sleep(60)


@app.route("/")
def logs():
    with tracer.trace("get_logs") as span:
        rows = get_logs()
        logs_list = [{"id": row[0], "message": row[1], "created_at": row[2].isoformat()} for row in rows]
        statsd.increment("misconfigbase.requests", tags=["environment:development"])
        span.set_tag("logs", logs_list)
        return jsonify(logs_list)


@app.route("/error")
def error():
    raise Exception("This is an error")


if __name__ == "__main__":
    log_thread = threading.Thread(target=log_periodically)
    log_thread.daemon = True
    log_thread.start()
    create_table()
    insert_thread = threading.Thread(target=insert_periodically)
    insert_thread.daemon = True
    insert_thread.start()
    app.run(host="0.0.0.0", port=80)
