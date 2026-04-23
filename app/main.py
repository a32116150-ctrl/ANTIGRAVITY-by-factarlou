import sys, os
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Slot, Property

from database import DatabaseManager
from scanner import ScannerManager
from printer import PrinterManager
from compliance import ComplianceManager

class POSBackend(QObject):
    # Signals for UI synchronization
    productsModelChanged = Signal()
    categoriesModelChanged = Signal()
    cartUpdated = Signal()
    currentViewChanged = Signal()
    dailySummaryChanged = Signal(dict)
    settingsChanged = Signal(dict)
    
    def __init__(self):
        super().__init__()
        self.db = DatabaseManager()
        self.scanner = ScannerManager()
        self.printer = PrinterManager()
        self.compliance = ComplianceManager()
        
        self._productsModel = []
        self._categoriesModel = []
        self._cart = []
        self._total = 0.0
        self._currentView = "sales"
        self._selectedCategory = 0
        self._dailySummary = {"date": "", "count": 0, "revenue": 0.0, "vat": 0.0}
        self._settings = {}
        
        # Connect Database signals
        self.db.productsModelChanged.connect(self._on_products_ready)
        self.db.categoriesModelChanged.connect(self._on_categories_ready)
        self.db.dailySummaryChanged.connect(self._on_daily_summary_ready)
        self.db.settingsLoaded.connect(self._on_settings_loaded)
        
        # Initial Load
        self.refreshInventory()
        self.loadSettings()

    def _on_products_ready(self, data):
        self._productsModel = data
        self.productsModelChanged.emit()

    def _on_categories_ready(self, data):
        self._categoriesModel = data
        self.categoriesModelChanged.emit()

    def _on_daily_summary_ready(self, data):
        self._dailySummary = data
        self.dailySummaryChanged.emit(data)

    def _on_settings_loaded(self, data):
        self._settings = data
        self.settingsChanged.emit(data)

    # --- Properties ---
    @Property(list, notify=productsModelChanged)
    def productsModel(self): return self._productsModel

    @Property(list, notify=categoriesModelChanged)
    def categoriesModel(self): return self._categoriesModel

    @Property(list, notify=categoriesModelChanged)
    def categoriesList(self): return self._categoriesModel

    @Property(list, notify=cartUpdated)
    def cart(self): return self._cart

    @Property(list, notify=cartUpdated)
    def cartModel(self): return self._cart

    @Property(float, notify=cartUpdated)
    def total(self): return self._total

    @Property(str, notify=currentViewChanged)
    def currentView(self): return self._currentView

    @Property(int, notify=currentViewChanged)
    def selectedCategory(self): return self._selectedCategory

    @Property(dict, notify=settingsChanged)
    def settings(self): return self._settings

    def getSetting(self, key, default=""): return self._settings.get(key, default)

    @Slot()
    def loadSettings(self):
        self.db.requestLoadSettings.emit()

    @Slot(str, str)
    def saveSetting(self, key, value):
        self.db.requestSaveSetting.emit(key, value)

    # --- Inventory Slots ---
    @Slot(str)
    def addCategorySlot(self, name):
        self.db.requestAddCategory.emit(name)

    @Slot(str, str, float, int, int, int)
    def addProductSlot(self, name, barcode, price, stock, cat_id, low_stock):
        self.db.requestAddProduct.emit(name, barcode, price, stock, cat_id, low_stock)

    @Slot(int, str, str, float, int, int, int)
    def updateProductSlot(self, pid, name, barcode, price, stock, cat_id, low_stock):
        self.db.requestUpdateProduct.emit(pid, name, barcode, price, stock, cat_id, low_stock)

    @Slot(int)
    def deleteProductSlot(self, pid):
        self.db.requestDeleteProduct.emit(pid)

    @Slot(int)
    def filterInventory(self, cat_id):
        self._selectedCategory = cat_id
        self.db.requestLoadProducts.emit(cat_id)
        self.currentViewChanged.emit()

    @Slot()
    def refreshInventory(self):
        self.db.requestLoadProducts.emit(0)
        self.db.requestLoadCategories.emit()

    # --- Sales Slots ---
    @Slot(int)
    def addToCart(self, pid):
        p = next((x for x in self._productsModel if x['id'] == pid), None)
        if p:
            item = next((x for x in self._cart if x['id'] == pid), None)
            if item:
                item['quantity'] += 1
            else:
                self._cart.append({"id": pid, "name": p['name'], "price": float(p['price']), "quantity": 1})
            self._update_total()

    @Slot(str)
    def addByBarcode(self, barcode):
        p = next((x for x in self._productsModel if x['barcode'] == barcode), None)
        if p: self.addToCart(p['id'])

    @Slot(int)
    def removeFromCart(self, index):
        if 0 <= index < len(self._cart):
            del self._cart[index]
            self._update_total()

    @Slot()
    def clearCart(self):
        self._cart = []
        self._update_total()

    def _update_total(self):
        self._total = sum(item['price'] * item['quantity'] for item in self._cart)
        self.cartUpdated.emit()

    @Slot()
    def checkout(self):
        if self._cart:
            tax_rate = float(self._settings.get('tax_rate', 19)) / 100
            store_tax_id = self._settings.get('store_tax_id', 'TN123456')
            tax = self._total * tax_rate
            compliance = self.compliance.get_teif_payload(store_tax_id, self._total, len(self._cart))
            self.db.requestRecordSale.emit(
                self._cart,
                compliance['iid'],
                compliance['qr_url'],
                self._total,
                tax
            )
            receipt_data = {
                "sale_id": compliance['iid'],
                "hash": compliance['iid'],
                "qr_url": compliance['qr_url'],
                "total": self._total,
                "items": self._cart,
                "title": self._settings.get('receipt_title', 'ANTIGRAVITY POS'),
                "store_name": self._settings.get('store_name', 'My Store')
            }
            self.printer.print_receipt(receipt_data)
            self.clearCart()

    @Slot()
    def request_daily_summary(self):
        self.db.requestGetDailySummary.emit()

    @Slot(dict)
    def print_z_report(self, summary):
        import datetime
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        receipts_dir = os.path.join(base_dir, "receipts")
        import os
        os.makedirs(receipts_dir, exist_ok=True)
        
        filename = os.path.join(receipts_dir, f"Z_REPORT_{summary.get('date', 'today')}.txt")
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
        import subprocess
        subprocess.run(['open', filename])

    @Slot(str)
    def changeView(self, view):
        self._currentView = view
        self.currentViewChanged.emit()

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    engine = QQmlApplicationEngine()
    backend = POSBackend()
    engine.rootContext().setContextProperty("posBackend", backend)
    engine.rootContext().setContextProperty("backend", backend)
    qml_file = os.path.join(os.path.dirname(__file__), "../ui/main.qml")
    engine.load(qml_file)
    if not engine.rootObjects(): sys.exit(-1)
    sys.exit(app.exec())
