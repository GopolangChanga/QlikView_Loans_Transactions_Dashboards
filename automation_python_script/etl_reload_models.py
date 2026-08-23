"""
etl_chain.py

Reloads a chain of QlikView models in strict sequence:
Extraction -> Stage -> Presentation

If any model fails (bad exit code, timeout, or missing file), the chain
stops immediately and later models are NOT run. Progress and errors are
written to both the console and a log file.
"""

import subprocess
import sys
import logging
from pathlib import Path

# --- Config ---

# Full path to the QlikView Desktop executable used to trigger reloads.
QV_PATH = Path(r"C:\Program Files\QlikView\qv.exe")

# The chain of models to reload, in order.
# Each entry is a (file_path, display_name) tuple.
# NOTE: the display name is just a label for logs — it does NOT affect
# which file actually gets reloaded. Make sure each path points to the
# correct .qvw for that stage.
MODELS = [
    (Path(r"LongPath\Bank_Stage.qvw"), "Extraction_QlikView: Bank_Extract"),   # TODO: verify this path — currently points to Bank_Stage.qvw, not an "Extract" file
    (Path(r"LongPath\Bank_Stage.qvw"), "Stage_QlikView: Bank_Stage"),
    (Path(r"LongPath\Bank_Dashbaord.qvw"), "Presentation_QlikView: Bank_Dashbaord")
]

# Where the run log gets written. Consider anchoring this to the script's
# own folder (Path(__file__).resolve().parent / "etl_chain.log") if this
# will be triggered by Task Scheduler, since the working directory isn't
# guaranteed there.
LOG_FILE = Path(r"LongPath\etl_chain.log")

# Max time (in seconds) to wait for a single model to finish reloading
# before giving up and treating it as failed. Prevents the whole chain
# from hanging forever if QlikView pops an interactive error dialog.
TIMEOUT_SECONDS = 3600   # 1 hour per model – adjust as needed

# --- Logging setup ---
# Writes every log line to both the log file and the console (stdout),
# so this works whether you're watching it run live or checking the
# log afterward (e.g. after an unattended/scheduled run).
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout),   # also log to console
    ],
)


def reload_model(path: Path, name: str) -> None:
    """
    Trigger a single QlikView reload via the command line and check the
    result. Exits the whole script (non-zero) on any failure, so the
    caller's loop never proceeds to the next model.
    """

    # Fail fast if the .qvw doesn't exist — avoids launching QlikView
    # against a path that will just error out anyway, and gives a
    # clearer message than QlikView's own error would.
    if not path.exists():
        logging.error(f"{name}: file not found → {path}")
        sys.exit(1)

    logging.info(f"Starting {name} ({path})...")

    try:
        # "/r" tells qv.exe to run a full reload, save, and close.
        # capture_output=True lets us log QlikView's own stdout/stderr
        # if something goes wrong (though the real error detail usually
        # lives in QlikView's own .log file, not here).
        result = subprocess.run(
            [str(QV_PATH), "/r", str(path)],
            capture_output=True,
            text=True,
            timeout=TIMEOUT_SECONDS,
        )
    except subprocess.TimeoutExpired:
        # Reload took longer than TIMEOUT_SECONDS — most commonly because
        # QlikView is stuck on an interactive error dialog (e.g. failed
        # SQL connection) and nothing is there to click it. Treat this
        # as a failure and stop the chain.
        logging.error(f"{name} timed out after {TIMEOUT_SECONDS}s")
        sys.exit(1)
    except Exception as e:
        # Catches anything unexpected (e.g. qv.exe itself couldn't be
        # launched) so the script doesn't crash with a raw traceback.
        logging.exception(f"{name} raised an unexpected exception")
        sys.exit(1)

    # A non-zero exit code means QlikView reported a reload failure
    # (e.g. script error, failed data source connection).
    if result.returncode != 0:
        logging.error(f"{name} failed with exit code {result.returncode}")
        if result.stdout:
            logging.error(f"stdout:\n{result.stdout}")
        if result.stderr:
            logging.error(f"stderr:\n{result.stderr}")
        print(f"ERROR: {name} failed. Halting chain.")
        # Exit with QlikView's own return code so anything monitoring
        # this script (e.g. Task Scheduler) can see it failed.
        sys.exit(result.returncode)

    logging.info(f"{name} succeeded.")
    print(f"{name} succeeded!")


def main() -> None:
    # Confirm QlikView itself is actually installed at the configured
    # path before attempting anything — avoids a confusing failure on
    # the very first model if this is just a bad path/typo.
    if not QV_PATH.exists():
        logging.error(f"QlikView executable not found: {QV_PATH}")
        sys.exit(1)

    # Run each model in order. reload_model() calls sys.exit() internally
    # on any failure, so this loop naturally stops the whole chain the
    # moment one stage fails — later models are never reached.
    for path, name in MODELS:
        reload_model(path, name)

    logging.info("ETL Pipeline completed successfully!")
    print("ETL Pipeline completed successfully!")


if __name__ == "__main__":
    main()
