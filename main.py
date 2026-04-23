import sys
import os
import json
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer

from app.database import Database
from app.compliance import Compliance
from app.hardware.scanner import Scanner
from app.hardware.printer import ThermalPrinter

class POSBackend(QObject):
    dataChanged = Signal()
    currentViewChanged = Signal()
    productsModelChanged = Signal(list)
    categoriesModelChanged = Signal(list)
    cartUpdated = Signal()
    dailySummaryChanged = Signal(dict)
    settingsChanged = Signal(dict)
    
    def __init__(self):
        super().__init__()
        self.db = Database.getInstance()
        self.printer = ThermalPrinter()
        self.scanner = Scanner()
        
        self._currentView = "sales"
        self._cart = []
        self._total = 0.0
        self._products = []
        self._categoriesList = []
        self._selectedCategory = 0
        self._settings = {}
        self._dailySummary = {"date": "", "count": 0, "revenue": 0, "vat": 0}
        
        self._load_settings()
        self._refresh_data()
        
    def _refresh_data(self):
        self._products = [dict(r) for r in self.db.get_products(self._selectedCategory)]
        self._categoriesList = [dict(r) for r in self.db.get_categories()]
        self.dataChanged.emit()

    # Properties
    @Property(str, notify=currentViewChanged)
    def currentView(self): return self._currentView

    @Property(list, notify=dataChanged)
    def cart(self): return self._cart

    @Property(float, notify=dataChanged)
    def total(self): return self._total

    @Property(list, notify=dataChanged)
    def products(self): return self._products

    @Property(list, notify=dataChanged)
    def categoriesList(self): return self._categoriesList

    @Property(int, notify=dataChanged)
    def selectedCategory(self): return self._selectedCategory

    @Property(dict, notify=dailySummaryChanged)
    def dailySummary(self): return self._dailySummary

    @Property(dict, notify=settingsChanged)
    def settings(self): return self._settings

    @Property(list, notify=dataChanged)
    def productsModel(self): return self._products

    @Property(list, notify=dataChanged)
    def categoriesModel(self): return self._categoriesList
        
    def _load_settings(self):
        try:
            rows = self.db.query("SELECT key, value FROM settings")
            if rows:
                self._settings = {r['key']: r['value'] for r in rows}
            else:
                self._settings = {
                    "store_name": "My Store",
                    "store_tax_id": "TN123456",
                    "receipt_title": "ANTIGRAVITY POS",
                    "tax_rate": "19",
                    "currency": "TND",
                    "low_stock_threshold": "5"
                }
            self.settingsChanged.emit(self._settings)
        except Exception as e:
            print(f"Error loading settings: {e}")
    
    @Slot()
    def loadSettings(self):
        self._load_settings()
        
    @Slot(str, str)
    def saveSetting(self, key, value):
        self.db.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, value))
        self._load_settings()

    @Slot(dict)
    def saveSettings(self, settings):
        for key, value in settings.items():
            self.db.execute("INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)", (key, str(value)))
        self._load_settings()
        
    @Slot()
    def request_daily_summary(self):
        try:
            rows = self.db.query("""SELECT COUNT(*) as count, COALESCE(SUM(total), 0) as revenue, COALESCE(SUM(tax), 0) as vat, DATE(created_at, 'localtime') as date FROM invoices WHERE DATE(created_at, 'localtime') = DATE('now', 'localtime')""")
            if rows and rows[0]['count'] > 0:
                self._dailySummary = dict(rows[0])
            else:
                from datetime import date
                self._dailySummary = {"date": str(date.today()), "count": 0, "revenue": 0, "vat": 0}
        except Exception as e:
            from datetime import date
            self._dailySummary = {"date": str(date.today()), "count": 0, "revenue": 0, "vat": 0}
        self.dailySummaryChanged.emit(self._dailySummary)

    # Slots
    # Slots
    @Slot(str)
    def changeView(self, view):
        self._currentView = view
        self.scanner.set_enabled(view == "sales")
        self.currentViewChanged.emit()

    @Slot(int)
    def filterByCategory(self, cat_id):
        self._selectedCategory = cat_id
        self._refresh_data()

    @Slot(int)
    def filterInventory(self, cat_id):
        self._selectedCategory = cat_id
        self._refresh_data()

    @Slot()
    def refreshInventory(self):
        self._refresh_data()

    @Slot(int)
    def addToCart(self, product_id):
        product = next((p for p in self._products if p['id'] == product_id), None)
        if product:
            existing = next((item for item in self._cart if item['id'] == product_id), None)
            if existing:
                existing['quantity'] += 1
            else:
                self._cart.append({
                    "id": product['id'],
                    "name": product['name'],
                    "price": float(product['price']),
                    "quantity": 1
                })
            self._update_total()

    @Slot(int)
    def removeFromCart(self, index):
        if 0 <= index < len(self._cart):
            del self._cart[index]
            self._update_total()

    @Slot(str)
    def searchProducts(self, query):
        if not query or len(query) < 2:
            self._refresh_data()
            return
        self._products = [dict(r) for r in self.db.search_products(query)]
        self.dataChanged.emit()

    @Slot()
    def clearCart(self):
        self._cart = []
        self._update_total()

    @Slot()
    def checkout(self):
        if not self._cart: return
        
        tax_rate = float(self._settings.get("tax_rate", 19))
        iid = Compliance.get_next_iid()
        total = self._total
        tax = round(total * (tax_rate / 100), 3)
        qr_data = Compliance.generate_qr_data(iid, total, tax)
        
        success = Compliance.save_invoice(iid, total, tax, qr_data, self._cart)
        
        if success:
            invoice_data = {"iid": iid, "total": total, "tax": tax, "qr_data": qr_data}
            self.printer.print_receipt(invoice_data, self._cart)
            self.clearCart()
            self._refresh_data()

    @Slot(str, str, float, int, int)
    def addProduct(self, name, barcode, price, stock, cat_id):
        try:
            self.db.execute(
                "INSERT INTO products (name, barcode, price, stock, category_id) VALUES (?, ?, ?, ?, ?)",
                (name, barcode, float(price or 0), int(stock or 0), cat_id)
            )
            self._refresh_data()
        except Exception as e:
            print(f"Error adding product: {e}")

    def _update_total(self):
        self._total = sum(
            (item.get('price') or 0.0) * (item.get('quantity') or 1)
            for item in self._cart
        )
        self.dataChanged.emit()

    @Slot(int)
    def deleteProduct(self, product_id):
        self.db.execute("DELETE FROM products WHERE id = ?", (product_id,))
        self._refresh_data()

    @Slot(int, str, str, float, int, int)
    def updateProduct(self, product_id, name, barcode, price, stock, cat_id):
        try:
            self.db.execute(
                "UPDATE products SET name=?, barcode=?, price=?, stock=?, category_id=? WHERE id=?",
                (name, barcode, float(price or 0), int(stock or 0), cat_id, product_id)
            )
            self._refresh_data()
        except Exception as e:
            print(f"Error updating product: {e}")

    @Slot(str)
    def addCategory(self, name):
        try:
            self.db.execute("INSERT OR IGNORE INTO categories (name) VALUES (?)", (name,))
            self._refresh_data()
        except Exception as e:
            print(f"Error adding category: {e}")

    @Slot(int, int)
    def cartItemQuantity(self, index, delta):
        if 0 <= index < len(self._cart):
            item = self._cart[index]
            new_qty = item.get('quantity', 1) + delta
            if new_qty <= 0:
                del self._cart[index]
            else:
                item['quantity'] = new_qty
            self._update_total()

    @Slot(int)
    def cartItemIncrement(self, index):
        self.cartItemQuantity(index, 1)

    @Slot(int)
    def cartItemDecrement(self, index):
        self.cartItemQuantity(index, -1)

    @Slot(str)
    def searchInvoices(self, iid):
        rows = self.db.query("SELECT * FROM invoices WHERE iid = ?", (iid,))
        return rows[0] if rows else None

    # Aliases for compatibility with different UI versions
    @Slot(int)
    def add_to_cart(self, product_id): self.addToCart(product_id)
    
    @Slot(int)
    def remove_from_cart(self, product_id):
        for i, item in enumerate(self._cart):
            if item['id'] == product_id:
                del self._cart[i]
                break
        self._update_total()

    @Slot()
    def clear_cart(self): self.clearCart()
    
    @Slot(str)
    def search_product(self, query): self.searchProducts(query)

    @Slot()
    def generateBarcode(self):
        import random
        return "".join([str(random.randint(0, 9)) for _ in range(13)])

    @Slot(str)
    def print_z_report(self, summary):
        import datetime, sys, traceback
        try:
            if summary is None:
                summary = {}
            base_dir = os.path.dirname(os.path.abspath(__file__))
            if not base_dir:
                base_dir = "."
            receipts_dir = os.path.join(base_dir, "receipts")
            os.makedirs(receipts_dir, exist_ok=True)
            
            date_str = summary.get('date', 'today') if summary else 'today'
            filename = os.path.join(receipts_dir, f"Z_REPORT_{date_str}.txt")
            lines = [
                "    DAILY Z-REPORT",
                "=" * 30,
                f"Date: {summary.get('date', 'N/A')}",
                "-" * 30,
                f"Transactions: {summary.get('count', 0)}",
                f"Revenue: {float(summary.get('revenue', 0)):.3f} TND",
                f"VAT Collected: {float(summary.get('vat', 0)):.3f} TND",
                "-" * 30,
                f"Total: {float(summary.get('revenue', 0)):.3f} TND",
                "=" * 30,
                datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            ]
            with open(filename, "w") as f:
                f.write("\n".join(lines))
                f.flush()
            sys.stdout.flush()
            import subprocess
            print("Z-Report:", filename, flush=True)
            subprocess.Popen(['open', filename])
        except Exception as e:
            print("Error:", e, flush=True)
            traceback.print_exc()

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    
    # Responsiveness & Window Sizing
    screen = app.primaryScreen().availableGeometry()
    screen_w = screen.width()
    screen_h = screen.height()
    
    # Priority: Full HD (1920x1080)
    target_w = 1920
    target_h = 1080
    
    # Adapt if screen is smaller
    if screen_w < target_w:
        target_w = int(screen_w * 0.95)
    if screen_h < target_h:
        target_h = int(screen_h * 0.9)

    backend = POSBackend()
    
    engine = QQmlApplicationEngine()
    
    # Expose screen info for adaptive QML
    engine.rootContext().setContextProperty("screenWidth", target_w)
    engine.rootContext().setContextProperty("screenHeight", target_h)
    engine.rootContext().setContextProperty("backend", backend)
    engine.rootContext().setContextProperty("posBackend", backend)
    
    qml_file = os.path.join(os.path.dirname(__file__), "ui/main.qml")
    engine.load(qml_file)
    
    if not engine.rootObjects():
        sys.exit(-1)
        
    sys.exit(app.exec())

