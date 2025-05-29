import sqlite3

def init_db():
    conn = sqlite3.connect('safety_data.db')  # Creates the database file
    cursor = conn.cursor()

    # Create table to store location data
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS location_data (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            time TEXT NOT NULL,
            safety_score REAL NOT NULL,
            report TEXT NOT NULL,
            image_path TEXT NOT NULL
        )
    ''')

    conn.commit()
    conn.close()

if __name__ == '__main__':
    init_db()
