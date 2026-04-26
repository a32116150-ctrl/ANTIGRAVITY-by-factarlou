Refactor scanner.py to use QThread worker pattern:

from PySide6.QtCore import QObject, Signal, Slot, QThread

class ScannerWorker(QObject):
    barcodeScanned = Signal(str)
    
    @Slot(str)
    def simulate_scan(self, barcode):
        print(f"Scanner: {barcode}")
        self.barcodeScanned.emit(barcode)

class ScannerManager(QObject):
    def __init__(self):
        super().__init__()
        self.thread = QThread()
        self.worker = ScannerWorker()
        self.worker.moveToThread(self.thread)
        self.thread.start()
    
    def shutdown(self):
        self.thread.quit()
        self.thread.wait(2000)