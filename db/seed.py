import sqlite3
import os

db_path = "db/antigravity.db"
os.makedirs("db", exist_ok=True)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create table if not exists
cursor.execute('''
    CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        barcode TEXT UNIQUE,
        name TEXT,
        price REAL,
        stock INTEGER,
        vat_rate REAL
    )
''')

# Insert mock products
products = [
    ("6191234567890", "Délice Milk 1L", 1.450, 100, 0.07),
    ("6190000000001", "Sabrine Water 1.5L", 0.750, 500, 0.07),
    ("6199999999999", "Couscous 1kg", 0.950, 200, 0.0),
    ("12345", "Test Product", 10.000, 10, 0.19)
]

cursor.executemany("INSERT OR IGNORE INTO products (barcode, name, price, stock, vat_rate) VALUES (?, ?, ?, ?, ?)", products)

conn.commit()
conn.close()
print(f"Database seeded at {db_path}")
