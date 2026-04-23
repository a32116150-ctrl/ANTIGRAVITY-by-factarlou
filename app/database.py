import sqlite3
import os
import logging
from PySide6.QtCore import QObject, Signal, Slot, QThread

class DatabaseWorker(QObject):
    productsModelChanged = Signal(list)
    categoriesModelChanged = Signal(list)
    dailySummaryChanged = Signal(dict)
    settingsLoaded = Signal(dict)
    errorOccurred = Signal(str)

    def __init__(self, db_path):
        super().__init__()
        self.db_path = db_path
        self.conn = None

    def connect(self):
        try:
            self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self.conn.row_factory = sqlite3.Row
            self._init_db()
        except Exception as e:
            print(f"Database connection error: {e}")
            self.errorOccurred.emit(str(e))

    def _init_db(self):
        c = self.conn.cursor()
        c.execute("PRAGMA journal_mode=WAL;")
        c.execute("CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE)")
        c.execute("""CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY AUTOINCREMENT, barcode TEXT UNIQUE, name TEXT,
            category_id INTEGER, price DECIMAL(10,3), stock INTEGER, low_stock_threshold INTEGER DEFAULT 5
        )""")
        c.execute("""CREATE TABLE IF NOT EXISTS invoices (
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            iid TEXT UNIQUE, 
            total DECIMAL(10,3), 
            tax DECIMAL(10,3), 
            qr TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )""")
        c.execute("""CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY,
            value TEXT
        )""")
        default_settings = [
            ("store_name", "My Store"),
            ("store_tax_id", "TN123456"),
            ("receipt_title", "ANTIGRAVITY POS"),
            ("tax_rate", "19"),
            ("currency", "TND"),
            ("low_stock_threshold", "5"),
            ("printer_enabled", "true"),
            ("scanner_enabled", "true"),
            ("theme_cyan", "#00F0FF"),
            ("theme_magenta", "#FF00AA"),
            ("theme_green", "#00FF88"),
            ("theme_gold", "#FFD700"),
            ("theme_background", "#1A1A2E"),
            ("theme_surface", "#252542"),
        ]
        for key, value in default_settings:
            c.execute("INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)", (key, value))
        self.conn.commit()

    @Slot(int)
    def loadProducts(self, cat_id=0):
        try:
            c = self.conn.cursor()
            sql = "SELECT p.*, IFNULL(c.name, 'Uncategorized') as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id"
            if cat_id > 0:
                sql += " WHERE p.category_id = ?"
                c.execute(sql, (cat_id,))
            else:
                c.execute(sql)
            self.productsModelChanged.emit([dict(r) for r in c.fetchall()])
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot()
    def loadCategories(self):
        try:
            c = self.conn.cursor()
            c.execute("SELECT * FROM categories ORDER BY name ASC")
            self.categoriesModelChanged.emit([dict(r) for r in c.fetchall()])
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot(str)
    def addCategory(self, name):
        try:
            c = self.conn.cursor()
            c.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (name,))
            self.conn.commit()
            self.loadCategories()
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot(str, str, float, int, int, int)
    def addProduct(self, name, barcode, price, stock, cat_id, low_stock):
        try:
            c = self.conn.cursor()
            c.execute("INSERT INTO products (name, barcode, price, stock, category_id, low_stock_threshold) VALUES (?, ?, ?, ?, ?, ?)",
                    (name, barcode, price, stock, cat_id, low_stock))
            self.conn.commit()
            self.loadProducts()
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot(int, str, str, float, int, int, int)
    def updateProduct(self, pid, name, barcode, price, stock, cat_id, low_stock):
        try:
            c = self.conn.cursor()
            c.execute("UPDATE products SET name=?, barcode=?, price=?, stock=?, category_id=?, low_stock_threshold=? WHERE id=?",
                    (name, barcode, price, stock, cat_id, low_stock, pid))
            self.conn.commit()
            self.loadProducts()
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot(int)
    def deleteProduct(self, pid):
        try:
            c = self.conn.cursor()
            c.execute("DELETE FROM products WHERE id=?", (pid,))
            self.conn.commit()
            self.loadProducts()
        except Exception as e: self.errorOccurred.emit(str(e))

    @Slot(list, str, str, float, float)
    def record_sale(self, items, iid, qr, total, tax):
        try:
            c = self.conn.cursor()
            c.execute("INSERT INTO invoices (iid, total, tax, qr) VALUES (?, ?, ?, ?)", (iid, total, tax, qr))
            for item in items:
                c.execute("UPDATE products SET stock = stock - ? WHERE id = ?", (item['quantity'], item['id']))
            self.conn.commit()
            self.loadProducts()
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot()
    def get_daily_summary(self):
        try:
            c = self.conn.cursor()
            c.execute("""SELECT 
                COUNT(*) as count, 
                COALESCE(SUM(total), 0) as revenue, 
                COALESCE(SUM(tax), 0) as vat,
                DATE(created_at, 'localtime') as date
            FROM invoices 
            WHERE DATE(created_at, 'localtime') = DATE('now', 'localtime')
            GROUP BY DATE(created_at, 'localtime')""")
            row = c.fetchone()
            if row:
                self.dailySummaryChanged.emit(dict(row))
            else:
                from datetime import date
                self.dailySummaryChanged.emit({
                    "date": str(date.today()),
                    "count": 0,
                    "revenue": 0.0,
                    "vat": 0.0
                })
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot()
    def load_settings(self):
        try:
            c = self.conn.cursor()
            c.execute("SELECT key, value FROM settings")
            rows = c.fetchall()
            settings = {r['key']: r['value'] for r in rows}
            self.settingsLoaded.emit(settings)
        except Exception as e:
            self.errorOccurred.emit(str(e))

    @Slot(str, str)
    def save_setting(self, key, value):
        try:
            c = self.conn.cursor()
            c.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, value))
            self.conn.commit()
            self.load_settings()
        except Exception as e:
            self.errorOccurred.emit(str(e))

class DatabaseManager(QObject):
    productsModelChanged = Signal(list)
    categoriesModelChanged = Signal(list)
    dailySummaryChanged = Signal(dict)
    settingsLoaded = Signal(dict)
    
    requestLoadProducts = Signal(int)
    requestLoadCategories = Signal()
    requestAddCategory = Signal(str)
    requestAddProduct = Signal(str, str, float, int, int, int)
    requestUpdateProduct = Signal(int, str, str, float, int, int, int)
    requestDeleteProduct = Signal(int)
    requestRecordSale = Signal(list, str, str, float, float)
    requestGetDailySummary = Signal()
    requestLoadSettings = Signal()
    requestSaveSetting = Signal(str, str)

    def __init__(self):
        super().__init__()
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        db_path = os.path.join(base_dir, "db", "antigravity.db")
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        
        self.thread = QThread()
        self.worker = DatabaseWorker(db_path)
        self.worker.moveToThread(self.thread)
        self.thread.started.connect(self.worker.connect)
        
        self.worker.productsModelChanged.connect(self.productsModelChanged)
        self.worker.categoriesModelChanged.connect(self.categoriesModelChanged)
        self.worker.dailySummaryChanged.connect(self.dailySummaryChanged)
        self.worker.settingsLoaded.connect(self.settingsLoaded)
        
        self.requestLoadProducts.connect(self.worker.loadProducts)
        self.requestLoadCategories.connect(self.worker.loadCategories)
        self.requestAddCategory.connect(self.worker.addCategory)
        self.requestAddProduct.connect(self.worker.addProduct)
        self.requestUpdateProduct.connect(self.worker.updateProduct)
        self.requestDeleteProduct.connect(self.worker.deleteProduct)
        self.requestRecordSale.connect(self.worker.record_sale)
        self.requestGetDailySummary.connect(self.worker.get_daily_summary)
        self.requestLoadSettings.connect(self.worker.load_settings)
        self.requestSaveSetting.connect(self.worker.save_setting)
        
        self.thread.start()


class _DatabaseWrapper:
    """Sync wrapper for root main.py compatibility"""
    _instance = None
    _db = None
    
    @classmethod
    def getInstance(cls):
        if cls._instance is None:
            cls._instance = cls()
            cls._db = DatabaseManager()
            import time
            time.sleep(0.5)
        return cls._instance
    
    def query(self, sql, params=()):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return []
        c = conn.cursor()
        c.execute(sql, params)
        return [dict(r) for r in c.fetchall()]
    
    def execute(self, sql, params=()):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return
        c = conn.cursor()
        c.execute(sql, params)
        conn.commit()
    
    def get_products(self, cat_id=0):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return []
        c = conn.cursor()
        sql = "SELECT p.*, IFNULL(c.name, 'Uncategorized') as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id"
        if cat_id > 0:
            sql += " WHERE p.category_id = ?"
            c.execute(sql, (cat_id,))
        else:
            c.execute(sql)
        return [dict(r) for r in c.fetchall()]
    
    def get_categories(self):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return []
        c = conn.cursor()
        c.execute("SELECT * FROM categories ORDER BY name ASC")
        return [dict(r) for r in c.fetchall()]
    
    def search_products(self, query):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return []
        c = conn.cursor()
        sql = """SELECT p.*, IFNULL(c.name, 'Uncategorized') as category_name 
                 FROM products p LEFT JOIN categories c ON p.category_id = c.id
                 WHERE p.name LIKE ? OR p.barcode LIKE ?"""
        pattern = f"%{query}%"
        c.execute(sql, (pattern, pattern))
        return [dict(r) for r in c.fetchall()]
    
    def search_invoices(self, iid):
        conn = _DatabaseWrapper._db.worker.conn
        if conn is None:
            return []
        c = conn.cursor()
        c.execute("SELECT * FROM invoices WHERE iid = ?", (iid,))
        row = c.fetchone()
        return dict(row) if row else None

Database = _DatabaseWrapper
