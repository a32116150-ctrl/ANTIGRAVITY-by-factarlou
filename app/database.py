import sqlite3
import os
from PySide6.QtCore import QObject, Signal, Slot, QThread


# ══════════════════════════════════════════════════════════════════════════════
# DATABASE WORKER  (lives on its own QThread — never call directly from UI)
# ══════════════════════════════════════════════════════════════════════════════
class DatabaseWorker(QObject):
    productsModelChanged  = Signal(list)
    categoriesModelChanged = Signal(list)
    dailySummaryChanged   = Signal(dict)
    settingsLoaded        = Signal(dict)
    errorOccurred         = Signal(str)

    def __init__(self, db_path):
        super().__init__()
        self.db_path = db_path
        self.conn    = None

    # ── lifecycle ─────────────────────────────────────────────────────────────
    def connect(self):
        try:
            self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self.conn.row_factory = sqlite3.Row
            self._init_db()
            # Boot-time load so the UI has data immediately
            self.loadProducts(0)
            self.loadCategories()
            self.load_settings()
        except Exception as e:
            print(f"[DB] Connection error: {e}")
            self.errorOccurred.emit(str(e))

    def _init_db(self):
        c = self.conn.cursor()
        c.execute("PRAGMA journal_mode=WAL;")
        c.execute("PRAGMA synchronous=NORMAL;")
        c.execute("""CREATE TABLE IF NOT EXISTS categories (
            id   INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL
        )""")
        c.execute("""CREATE TABLE IF NOT EXISTS products (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            barcode             TEXT UNIQUE,
            name                TEXT NOT NULL,
            category_id         INTEGER REFERENCES categories(id) ON DELETE SET NULL,
            price               DECIMAL(10,3) NOT NULL DEFAULT 0,
            stock               INTEGER NOT NULL DEFAULT 0,
            low_stock_threshold INTEGER NOT NULL DEFAULT 5
        )""")
        c.execute("""CREATE TABLE IF NOT EXISTS invoices (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            iid        TEXT UNIQUE,
            total      DECIMAL(10,3),
            tax        DECIMAL(10,3),
            qr         TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )""")
        c.execute("""CREATE TABLE IF NOT EXISTS settings (
            key   TEXT PRIMARY KEY,
            value TEXT
        )""")

        default_settings = [
            ("store_name",              "My Store"),
            ("store_tax_id",            ""),          # Set during initial configuration
            ("store_phone",             ""),
            ("store_address",           ""),
            ("receipt_title",           "ANTIGRAVITY POS"),
            ("tax_rate",                "0"),          # Set based on local tax law
            ("currency",                "USD"),        # ISO 4217 currency code
            ("currency_symbol",         "$"),          # Display symbol
            ("low_stock_threshold",     "5"),
            ("printer_enabled",         "true"),
            ("scanner_enabled",         "true"),
            ("compliance_url_template", ""),          # e.g. https://verify.example.com/?iid={iid}&total={total}
            ("paper_width_mm",          "80"),         # 58 or 80
            ("date_format",             "%Y-%m-%d"),   # ISO default; override per locale
            ("decimal_separator",       "."),          # . or ,
        ]
        c.executemany(
            "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)",
            default_settings
        )
        self.conn.commit()

    # ── products ──────────────────────────────────────────────────────────────
    @Slot(int)
    def loadProducts(self, cat_id=0):
        try:
            c = self.conn.cursor()
            sql = """
                SELECT
                    p.*,
                    IFNULL(cat.name, 'Uncategorized') AS category_name
                FROM products p
                LEFT JOIN categories cat ON p.category_id = cat.id
            """
            if cat_id > 0:
                sql += " WHERE p.category_id = ?"
                c.execute(sql, (cat_id,))
            else:
                c.execute(sql)
            self.productsModelChanged.emit([dict(r) for r in c.fetchall()])
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str, float, int, int, int)
    def addProduct(self, name, barcode, price, stock, cat_id, low_stock):
        try:
            c = self.conn.cursor()
            c.execute(
                "INSERT INTO products (name, barcode, price, stock, category_id, low_stock_threshold) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (name, barcode or None, price, stock, cat_id or None, low_stock)
            )
            self.conn.commit()
            self.loadProducts(0)
            self.loadCategories()        # refresh product_count
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(int, str, str, float, int, int, int)
    def updateProduct(self, pid, name, barcode, price, stock, cat_id, low_stock):
        try:
            c = self.conn.cursor()
            c.execute(
                "UPDATE products SET name=?, barcode=?, price=?, stock=?, "
                "category_id=?, low_stock_threshold=? WHERE id=?",
                (name, barcode or None, price, stock, cat_id or None, low_stock, pid)
            )
            self.conn.commit()
            self.loadProducts(0)
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(int)
    def deleteProduct(self, pid):
        try:
            c = self.conn.cursor()
            c.execute("DELETE FROM products WHERE id=?", (pid,))
            self.conn.commit()
            self.loadProducts(0)
            self.loadCategories()        # refresh product_count
        except Exception as e:
            self.errorOccurred.emit(str(e))

    # ── categories ────────────────────────────────────────────────────────────
    @Slot()
    def loadCategories(self):
        try:
            c = self.conn.cursor()
            # Include product_count so the Categories tab can display it
            c.execute("""
                SELECT
                    cat.id,
                    cat.name,
                    COUNT(p.id) AS product_count
                FROM categories cat
                LEFT JOIN products p ON p.category_id = cat.id
                GROUP BY cat.id
                ORDER BY cat.name ASC
            """)
            self.categoriesModelChanged.emit([dict(r) for r in c.fetchall()])
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str)
    def addCategory(self, name):
        try:
            c = self.conn.cursor()
            c.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (name.strip(),))
            self.conn.commit()
            self.loadCategories()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(int)
    def deleteCategory(self, cat_id):
        try:
            c = self.conn.cursor()
            # Detach products from this category before deleting
            c.execute("UPDATE products SET category_id = NULL WHERE category_id = ?", (cat_id,))
            c.execute("DELETE FROM categories WHERE id = ?", (cat_id,))
            self.conn.commit()
            self.loadCategories()
            self.loadProducts(0)         # products now show as Uncategorized
        except Exception as e:
            self.errorOccurred.emit(str(e))

    # ── sales ─────────────────────────────────────────────────────────────────
    @Slot(list, str, str, float, float)
    def record_sale(self, items, iid, qr, total, tax):
        try:
            c = self.conn.cursor()
            c.execute(
                "INSERT INTO invoices (iid, total, tax, qr) VALUES (?, ?, ?, ?)",
                (iid, total, tax, qr)
            )
            for item in items:
                c.execute(
                    "UPDATE products SET stock = stock - ? WHERE id = ?",
                    (item['quantity'], item['id'])
                )
            self.conn.commit()
            self.loadProducts(0)
        except Exception as e:
            self.errorOccurred.emit(str(e))

    # ── analytics ─────────────────────────────────────────────────────────────
    @Slot()
    def get_daily_summary(self):
        try:
            c = self.conn.cursor()
            c.execute("""
                SELECT
                    COUNT(*)              AS count,
                    COALESCE(SUM(total),0) AS revenue,
                    COALESCE(SUM(tax),  0) AS vat,
                    DATE(created_at, 'localtime') AS date
                FROM invoices
                WHERE DATE(created_at, 'localtime') = DATE('now', 'localtime')
                GROUP BY DATE(created_at, 'localtime')
            """)
            row = c.fetchone()
            from datetime import date
            self.dailySummaryChanged.emit(
                dict(row) if row else
                {"date": str(date.today()), "count": 0, "revenue": 0.0, "vat": 0.0}
            )
        except Exception as e:
            self.errorOccurred.emit(str(e))

    # ── settings ──────────────────────────────────────────────────────────────
    @Slot()
    def load_settings(self):
        try:
            c = self.conn.cursor()
            c.execute("SELECT key, value FROM settings")
            self.settingsLoaded.emit({r['key']: r['value'] for r in c.fetchall()})
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str)
    def save_setting(self, key, value):
        try:
            c = self.conn.cursor()
            c.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                (key, value)
            )
            self.conn.commit()
            self.load_settings()
        except Exception as e:
            self.errorOccurred.emit(str(e))


# ══════════════════════════════════════════════════════════════════════════════
# DATABASE MANAGER  (thread-safe signal bridge — use this from the UI thread)
# ══════════════════════════════════════════════════════════════════════════════
class DatabaseManager(QObject):
    # outbound signals (worker → UI)
    productsModelChanged  = Signal(list)
    categoriesModelChanged = Signal(list)
    dailySummaryChanged   = Signal(dict)
    settingsLoaded        = Signal(dict)

    # inbound request signals (UI → worker)
    requestLoadProducts    = Signal(int)
    requestLoadCategories  = Signal()
    requestAddCategory     = Signal(str)
    requestDeleteCategory  = Signal(int)
    requestAddProduct      = Signal(str, str, float, int, int, int)
    requestUpdateProduct   = Signal(int, str, str, float, int, int, int)
    requestDeleteProduct   = Signal(int)
    requestRecordSale      = Signal(list, str, str, float, float)
    requestGetDailySummary = Signal()
    requestLoadSettings    = Signal()
    requestSaveSetting     = Signal(str, str)

    def __init__(self):
        super().__init__()
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        db_path  = os.path.join(base_dir, "db", "antigravity.db")
        os.makedirs(os.path.dirname(db_path), exist_ok=True)

        self.thread = QThread()
        self.worker = DatabaseWorker(db_path)
        self.worker.moveToThread(self.thread)

        # Start worker on thread ready
        self.thread.started.connect(self.worker.connect)

        # Worker → Manager (re-emit outward)
        self.worker.productsModelChanged.connect(self.productsModelChanged)
        self.worker.categoriesModelChanged.connect(self.categoriesModelChanged)
        self.worker.dailySummaryChanged.connect(self.dailySummaryChanged)
        self.worker.settingsLoaded.connect(self.settingsLoaded)
        self.worker.errorOccurred.connect(
            lambda msg: print(f"[DB ERROR] {msg}")
        )

        # Manager → Worker (queue across thread boundary)
        self.requestLoadProducts.connect(self.worker.loadProducts)
        self.requestLoadCategories.connect(self.worker.loadCategories)
        self.requestAddCategory.connect(self.worker.addCategory)
        self.requestDeleteCategory.connect(self.worker.deleteCategory)
        self.requestAddProduct.connect(self.worker.addProduct)
        self.requestUpdateProduct.connect(self.worker.updateProduct)
        self.requestDeleteProduct.connect(self.worker.deleteProduct)
        self.requestRecordSale.connect(self.worker.record_sale)
        self.requestGetDailySummary.connect(self.worker.get_daily_summary)
        self.requestLoadSettings.connect(self.worker.load_settings)
        self.requestSaveSetting.connect(self.worker.save_setting)

        self.thread.start()


# ══════════════════════════════════════════════════════════════════════════════
# SYNC WRAPPER  (used by compliance / printer helpers that need direct SQL)
# ══════════════════════════════════════════════════════════════════════════════
class _DatabaseWrapper:
    _instance = None
    _db: DatabaseManager = None

    @classmethod
    def getInstance(cls):
        if cls._instance is None:
            cls._instance = cls()
            cls._db = DatabaseManager()
            import time; time.sleep(0.3)   # let the thread start
        return cls._instance

    def _conn(self):
        return self._db.worker.conn

    def query(self, sql, params=()):
        c = self._conn().cursor()
        c.execute(sql, params)
        return [dict(r) for r in c.fetchall()]

    def execute(self, sql, params=()):
        conn = self._conn()
        conn.cursor().execute(sql, params)
        conn.commit()

    def get_products(self, cat_id=0):
        sql = """
            SELECT p.*, IFNULL(cat.name, 'Uncategorized') AS category_name
            FROM products p LEFT JOIN categories cat ON p.category_id = cat.id
        """
        params = ()
        if cat_id > 0:
            sql += " WHERE p.category_id = ?"
            params = (cat_id,)
        return self.query(sql, params)

    def get_categories(self):
        return self.query("""
            SELECT cat.*, COUNT(p.id) AS product_count
            FROM categories cat
            LEFT JOIN products p ON p.category_id = cat.id
            GROUP BY cat.id ORDER BY cat.name ASC
        """)

    def search_products(self, query):
        pattern = f"%{query}%"
        return self.query("""
            SELECT p.*, IFNULL(cat.name, 'Uncategorized') AS category_name
            FROM products p LEFT JOIN categories cat ON p.category_id = cat.id
            WHERE p.name LIKE ? OR p.barcode LIKE ?
        """, (pattern, pattern))

    def search_invoices(self, iid):
        rows = self.query("SELECT * FROM invoices WHERE iid = ?", (iid,))
        return rows[0] if rows else None


Database = _DatabaseWrapper