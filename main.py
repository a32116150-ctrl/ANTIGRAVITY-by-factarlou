import sys
import os
import json
import datetime
import subprocess
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Property, Signal, Slot, QTimer, QThread, Qt

# Local imports
from app.database import Database, DatabaseManager
from app.compliance import Compliance
from app.hardware.scanner import Scanner
from app.hardware.printer import ThermalPrinter

# ══════════════════════════════════════════════════════════════════════════════
# MAIN BACKEND CONTROLLER
# ══════════════════════════════════════════════════════════════════════════════
class POSBackend(QObject):
    dataChanged = Signal()
    currentViewChanged = Signal()
    productsModelChanged = Signal(list)
    categoriesModelChanged = Signal(list)
    cartUpdated = Signal()
    dailySummaryChanged = Signal(dict)
    settingsChanged = Signal(dict)
    
    # Error & Status Signals
    errorMessage = Signal(str)
    printerStatusMessage = Signal(str)
    printerOnline = Signal(bool)
    printersFound = Signal(list)
    
    # Internal Signals
    request_print = Signal(dict, list)
    
    def __init__(self):
        super().__init__()
        
        # 1. Initialize Threaded Managers
        try:
            self.db_manager = DatabaseManager()
            self.printer_manager = ThermalPrinter(self.db_manager)
            self.scanner = Scanner()
        except Exception as e:
            print(f"Startup Error: {e}")
            sys.exit(1)
        
        # 2. Connect Printer Worker Signals
        self.printer_worker = self.printer_manager.worker
        self.request_print.connect(self.printer_worker.do_print)
        self.printer_worker.printerStatusChanged.connect(self.printerStatusMessage.emit)
        self.printer_worker.printerConnected.connect(self._on_printer_status)
        self.printer_worker.printerDiscovered.connect(self.printersFound.emit)
        self.printer_worker.printError.connect(self.errorMessage.emit)

        # 3. Timers
        self.memory_timer = QTimer()
        self.memory_timer.timeout.connect(self._check_memory)
        self.memory_timer.start(60000)

        # 4. State
        self._currentView = "sales"
        self._cart = []
        self._total = 0.0
        self._products = []
        self._categoriesList = []
        self._selectedCategory = 0
        self._settings = {}
        self._dailySummary = {"date": "", "count": 0, "revenue": 0, "vat": 0}
        self._printer_status = False
        
        # 5. Connect Database Signals
        self.db_manager.productsModelChanged.connect(self._on_products_loaded, Qt.QueuedConnection)
        self.db_manager.categoriesModelChanged.connect(self._on_categories_loaded, Qt.QueuedConnection)
        self.db_manager.dailySummaryChanged.connect(self._on_summary_loaded, Qt.QueuedConnection)
        self.db_manager.settingsLoaded.connect(self._on_settings_loaded, Qt.QueuedConnection)
        
        # 6. Connect Scanner
        self.scanner.barcode_received.connect(self._on_barcode_scanned)
        
        self.db_manager.requestLoadSettings.emit()
        self.refreshInventory()
        
    @Property(bool, notify=dataChanged)
    def isPrinterOnline(self): return self._printer_status

    def _on_printer_status(self, online):
        self._printer_status = online
        self.printerOnline.emit(online)
        self.dataChanged.emit()

    def _check_memory(self):
        try:
            import psutil
            process = psutil.Process(os.getpid())
            mem_mb = process.memory_info().rss / (1024 * 1024)
            if mem_mb > 400:
                self.errorMessage.emit("Memory Usage High. Optimizing resources...")
        except ImportError: pass

    # --- DATA SYNC SLOTS ---
    def _on_products_loaded(self, data):
        self._products = data[:50]
        self.productsModelChanged.emit(self._products)
        self.dataChanged.emit()

    def _on_categories_loaded(self, data):
        self._categoriesList = data
        self.categoriesModelChanged.emit(data)
        self.dataChanged.emit()

    def _on_summary_loaded(self, data):
        self._dailySummary = data
        self.dailySummaryChanged.emit(data)

    def _on_settings_loaded(self, data):
        self._settings = data
        self.settingsChanged.emit(data)

    def _on_barcode_scanned(self, barcode):
        product = next((p for p in self._products if p.get('barcode') == barcode), None)
        if product: self.addToCart(product['id'])

    # --- PROPERTIES ---
    @Property(str, notify=currentViewChanged)
    def currentView(self): return self._currentView
    @Property(list, notify=dataChanged)
    def cart(self): return self._cart
    @Property(float, notify=dataChanged)
    def total(self): return self._total
    @Property(list, notify=dataChanged)
    def productsModel(self): return self._products
    @Property(list, notify=dataChanged)
    def categoriesModel(self): return self._categoriesList
    @Property(dict, notify=dailySummaryChanged)
    def dailySummary(self): return self._dailySummary
    @Property(dict, notify=settingsChanged)
    def settings(self): return self._settings

    # --- UI SLOTS ---
    @Slot(str)
    def changeView(self, view):
        self._currentView = view
        self.scanner.request_set_enabled.emit(view == "sales")
        self.currentViewChanged.emit()

    @Slot()
    def scanPrinters(self):
        self.printer_worker.scan_printers()

    @Slot(str, str)
    def connectPrinter(self, address, p_type):
        self.printer_worker.connect_printer(address, p_type)

    @Slot()
    def refreshInventory(self):
        try:
            self.db_manager.requestLoadProducts.emit(self._selectedCategory)
            self.db_manager.requestLoadCategories.emit()
        except Exception as e:
            self.errorMessage.emit(f"Database error: {e}")

    @Slot(int)
    def filterByCategory(self, cat_id):
        self._selectedCategory = cat_id
        self.db_manager.requestLoadProducts.emit(cat_id)

    @Slot(int)
    def addToCart(self, product_id):
        product = next((p for p in self._products if p['id'] == product_id), None)
        if product:
            existing = next((item for item in self._cart if item['id'] == product_id), None)
            if existing: existing['quantity'] += 1
            else:
                self._cart.append({"id": product['id'], "name": product['name'], "price": float(product['price']), "quantity": 1})
            self._update_total()

    def _update_total(self):
        self._total = sum((item.get('price', 0) * item.get('quantity', 1)) for item in self._cart)
        self.dataChanged.emit()

    @Slot()
    def checkout(self):
        if not self._cart: return
        try:
            tax_rate = float(self._settings.get("tax_rate", 19))
            iid = Compliance.get_next_iid()
            total = self._total
            tax = round(total * (tax_rate / 100), 3)
            qr_data = Compliance.generate_qr_data(iid, total, tax)
            self.db_manager.requestRecordSale.emit(self._cart, iid, qr_data, total, tax)
            self.request_print.emit({"iid": iid, "total": total, "tax": tax, "qr_data": qr_data}, list(self._cart))
            self._cart = []
            self._update_total()
            self.refreshInventory()
            self.request_daily_summary()
        except Exception as e:
            self.errorMessage.emit(f"Checkout failed: {e}")

    @Slot()
    def request_daily_summary(self):
        self.db_manager.requestGetDailySummary.emit()

    @Slot(dict)
    def saveSettings(self, settings):
        try:
            for k, v in settings.items():
                self.db_manager.requestSaveSetting.emit(k, str(v))
        except Exception as e:
            self.errorMessage.emit(f"Failed to save settings: {e}")

    @Slot(str, str, float, int, int)
    def addProduct(self, name, barcode, price, stock, cat_id):
        self.db_manager.requestAddProduct.emit(name, barcode, price, stock, cat_id, 5)

    @Slot(int)
    def deleteProduct(self, pid):
        self.db_manager.requestDeleteProduct.emit(pid)

    @Slot(int, str, str, float, int, int)
    def updateProduct(self, pid, name, barcode, price, stock, cat_id):
        self.db_manager.requestUpdateProduct.emit(pid, name, barcode, price, stock, cat_id, 5)

    @Slot(int)
    def cartItemIncrement(self, index):
        if 0 <= index < len(self._cart):
            self._cart[index]['quantity'] += 1
            self._update_total()

    @Slot(int)
    def cartItemDecrement(self, index):
        if 0 <= index < len(self._cart):
            self._cart[index]['quantity'] -= 1
            if self._cart[index]['quantity'] <= 0: del self._cart[index]
            self._update_total()

    @Slot(dict)
    def print_z_report(self, summary):
        try:
            base_dir = os.path.expanduser("~") if sys.platform == "linux" else os.path.dirname(os.path.abspath(__file__))
            reports_dir = os.path.join(base_dir, "reports") if sys.platform == "linux" else os.path.join(base_dir, "receipts")
            os.makedirs(reports_dir, exist_ok=True)
            date_str = summary.get('date', 'today')
            filename = os.path.join(reports_dir, f"Z_REPORT_{date_str}.txt")
            content = f"    DAILY Z-REPORT\n" + "="*27 + f"\nDate: {date_str}\nTransactions: {summary.get('count', 0)}\nRevenue: {float(summary.get('revenue', 0)):.3f} TND\nVAT: {float(summary.get('vat', 0)):.3f} TND\n" + "="*27 + "\n"
            with open(filename, "w") as f: f.write(content)

            if sys.platform == "linux":
                if self.isPrinterOnline:
                    self.request_print.emit({"iid": "Z-REPORT", "total": summary.get('revenue', 0), "qr_data": ""}, [{"name": "DAILY REVENUE", "price": summary.get('revenue', 0), "quantity": 1}])
                else: self.errorMessage.emit(f"Report saved to {filename}")
            elif sys.platform == "darwin": subprocess.Popen(["open", filename])
            elif sys.platform == "win32": os.startfile(filename)
        except Exception as e:
            self.errorMessage.emit(f"Z-Report Error: {e}")

    def shutdown(self):
        self.memory_timer.stop()
        self.scanner.stop()
        self.printer_manager.stop()
        self.db_manager.thread.quit()
        self.db_manager.thread.wait()

if __name__ == "__main__":
    QGuiApplication.setAttribute(Qt.AA_EnableHighDpiScaling, False)
    app = QGuiApplication(sys.argv)
    os.environ["QT_QUICK_CONTROLS_STYLE"] = "Basic"
    backend = POSBackend()
    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("posBackend", backend)
    qml_file = os.path.join(os.path.dirname(__file__), "ui/main.qml")
    engine.load(qml_file)
    if not engine.rootObjects(): sys.exit(-1)
    exit_code = app.exec()
    backend.shutdown()
    sys.exit(exit_code)
