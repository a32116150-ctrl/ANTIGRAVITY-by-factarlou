import os
from datetime import datetime

try:
    import serial
    HAS_SERIAL = True
except ImportError:
    HAS_SERIAL = False

class ThermalPrinter:
    def __init__(self, port="/dev/ttyUSB0", baudrate=9600):
        self.port = port
        self.baudrate = baudrate
        self.online = False
        try:
            if HAS_SERIAL:
                # self.ser = serial.Serial(port, baudrate, timeout=1)
                pass
            self.online = True
        except:
            self.online = False

    def print_receipt(self, invoice_data, cart_items):
        receipt_text = self._generate_text(invoice_data, cart_items)
        
        if self.online:
            try:
                # self.ser.write(receipt_text.encode('ascii'))
                # self._print_qr(invoice_data['qr_data'])
                print("--- PRINTING TO HARDWARE ---")
                print(receipt_text)
                return True
            except:
                self.online = False
        
        # Fallback: Save to file
        filename = f"receipts/{invoice_data['iid']}.txt"
        os.makedirs("receipts", exist_ok=True)
        with open(filename, "w") as f:
            f.write(receipt_text)
            f.write(f"\nQR DATA: {invoice_data['qr_data']}\n")
        
        print(f"Printer Offline. Receipt saved to {filename}")
        return False

    def _generate_text(self, invoice, items):
        now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        lines = [
            "      ANTIGRAVITY POS      ",
            "---------------------------",
            f"IID: {invoice['iid']}",
            f"DATE: {now}",
            "---------------------------",
            "QTY  ITEM             PRICE",
        ]
        
        for item in items:
            name = (item['name'][:15] + "..") if len(item['name']) > 15 else item['name'].ljust(17)
            line = f"{str(item['quantity']).ljust(4)} {name} {float(item['price']):.3f}"
            lines.append(line)
            
        lines.append("---------------------------")
        lines.append(f"TOTAL:           {float(invoice['total']):.3f} TND")
        lines.append("---------------------------")
        lines.append("    THANK YOU FOR YOUR     ")
        lines.append("         PURCHASE!         ")
        
        return "\n".join(lines)

    def _print_qr(self, data):
        # Implementation for thermal printer QR command would go here
        pass
