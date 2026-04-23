import os
import subprocess
from PySide6.QtCore import QObject, Signal, Property

class PrinterManager(QObject):
    statusChanged = Signal(bool)

    def __init__(self):
        super().__init__()
        self._online = True
        self.base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        self.receipts_dir = os.path.join(self.base_dir, "receipts")
        os.makedirs(self.receipts_dir, exist_ok=True)
        print("PrinterManager: Simulated Printer (macOS)")

    @Property(bool, notify=statusChanged)
    def is_online(self):
        return self._online

    def print_receipt(self, receipt_data):
        """
        Expects a dict with: total, items, qr_url, sale_id, hash, title, store_name
        """
        title = receipt_data.get('title', 'ANTIGRAVITY POS')
        store_name = receipt_data.get('store_name', 'My Store')
        currency = receipt_data.get('currency', 'TND')
        
        filename = os.path.join(self.receipts_dir, f"{receipt_data['sale_id']}.txt")
        
        lines = [
            f"      {title}",
            "=" * 30,
            store_name,
            "-" * 30,
            f"SALE ID: {receipt_data['sale_id']}",
            f"HASH: {receipt_data['hash']}",
            "-" * 30,
            "QTY  ITEM             PRICE"
        ]
        
        for item in receipt_data['items']:
            name = (item['name'][:15] + "..") if len(item['name']) > 15 else item['name'].ljust(17)
            line = f"{str(item['quantity']).ljust(4)} {name} {float(item['price']):.3f}"
            lines.append(line)
            
        lines.append("=" * 30)
        lines.append(f"TOTAL:           {float(receipt_data['total']):.3f} {currency}")
        lines.append(f"QR: {receipt_data['qr_url']}")
        lines.append("=" * 30)
        lines.append("    THANK YOU FOR YOUR     ")
        lines.append("         PURCHASE!         ")
        
        try:
            with open(filename, "w") as f:
                f.write("\n".join(lines))
            
            print(f"PrinterManager: Receipt saved to {filename}")
            if os.name == 'posix':
                subprocess.run(['open', filename])
            return True
        except Exception as e:
            print(f"PrinterManager Error: {e}")
            return False
