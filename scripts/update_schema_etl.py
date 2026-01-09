
import sqlite3
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

DB_PATH = '/home/adminlotfy/project/assets/database/mediswitch.db'

def update_schema():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        # Add column for Structured Dosage JSON (Compressed BLOB or Text)
        # We will use BLOB to store zlib compressed JSON as requested for efficiency
        logging.info("Adding 'structured_dosage' column to dosage_guidelines table...")
        cursor.execute("ALTER TABLE dosage_guidelines ADD COLUMN structured_dosage BLOB")
        conn.commit()
        logging.info("Column 'structured_dosage' added successfully.")
    except sqlite3.OperationalError as e:
        if "duplicate column" in str(e).lower():
            logging.info("Column 'structured_dosage' already exists.")
        else:
            logging.error(f"Error updating schema: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    update_schema()
