from PySide6.QtCore import QObject, Signal, Slot

class ScannerManager(QObject):
    barcodeScanned = Signal(str)

    def __init__(self):
        super().__init__()
        print("ScannerManager: Simulated Scanner (macOS)")

    @Slot(str)
    def simulate_scan(self, barcode):
        """Allows manual simulation from UI"""
        print(f"ScannerManager: Scanned -> {barcode}")
        self.barcodeScanned.emit(barcode)
