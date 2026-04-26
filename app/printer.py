Rewrite printer.py from scratch with this exact architecture:

--- FILE: printer.py ---

import os
import asyncio
import sqlite3
from datetime import datetime
from PySide6.QtCore import QObject, Signal, Slot, QTimer
from escpos.printer import Network
from escpos.exceptions import Error as EscposError

try:
    from bleak import BleakScanner, BleakClient
    BLEAK_AVAILABLE = True
except ImportError:
    BLEAK_AVAILABLE = False

class PrinterWorker(QObject):
    # Signals to UI
    printSuccess = Signal(str)
    printError = Signal(str)
    printerDiscovered = Signal(list)  # List of dicts: {name, address, type, rssi}
    printerConnected = Signal(bool)
    printerStatusChanged = Signal(str)  # "online", "offline", "scanning", "printing"
    pendingCountChanged = Signal(int)
    
    # Signals from Backend
    requestPrint = Signal(dict)
    requestScan = Signal()
    requestConnect = Signal(str, str)  # address, type ("bluetooth" or "wifi")
    requestDisconnect = Signal()

    def __init__(self, db_path="antigravity.db"):
        super().__init__()
        self.db_path = db_path
        self._printer = None
        self._printer_type = None
        self._printer_address = None
        self._pending_queue = []
        self._retry_timer = QTimer()
        self._retry_timer.timeout.connect(self._flush_pending)
        self._retry_timer.start(30000)  # Retry every 30s
        self.requestPrint.connect(self._do_print)
        self.requestScan.connect(self._do_scan)
        self.requestConnect.connect(self._do_connect)
        self.requestDisconnect.connect(self._do_disconnect)
        self._init_pending_table()

    def _init_pending_table(self):
        conn = sqlite3.connect(self.db_path)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS pending_prints (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                receipt_data TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        conn.close()

    @Slot()
    def _do_scan(self):
        self.printerStatusChanged.emit("scanning")
        found = []
        # Bluetooth scan
        if BLEAK_AVAILABLE:
            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                devices = loop.run_until_complete(
                    BleakScanner.discover(timeout=8.0)
                )
                for d in devices:
                    name = d.name or "Unknown"
                    if any(k in name.upper() for k in ["PRINTER","POS","THERMAL","XPRINTER","RONGTA","EPSON","58MM","80MM"]):
                        found.append({
                            "name": name,
                            "address": d.address,
                            "type": "bluetooth",
                            "rssi": d.rssi or 0
                        })
            except Exception as e:
                print(f"BT Scan Error: {e}")
        
        # WiFi scan (only if no BT found, to save time)
        if not found:
            try:
                import socket
                subnet = "192.168.1."
                for i in range(1, 255):
                    for port in [9100, 515]:
                        try:
                            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                            s.settimeout(0.2)
                            result = s.connect_ex((subnet + str(i), port))
                            if result == 0:
                                found.append({
                                    "name": f"Network Printer {subnet}{i}",
                                    "address": f"{subnet}{i}:{port}",
                                    "type": "wifi",
                                    "rssi": 0
                                })
                            s.close()
                        except:
                            pass
            except Exception as e:
                print(f"WiFi Scan Error: {e}")
        
        self.printerDiscovered.emit(found)
        self.printerStatusChanged.emit("offline" if not self._printer else "online")

    @Slot(str, str)
    def _do_connect(self, address, ptype):
        self.printerStatusChanged.emit("scanning")
        try:
            if ptype == "wifi":
                ip, port = address.split(":")
                self._printer = Network(ip, port=int(port))
                self._printer.text("\n")  # Test connection
            elif ptype == "bluetooth" and BLEAK_AVAILABLE:
                # For Bluetooth ESC/POS, use bleak to connect then wrap with escpos
                # Note: python-escpos Bluetooth support varies by platform
                # Fallback: store address and use raw socket if needed
                self._printer_address = address
                self._printer = None  # Will use raw BT write in _do_print
            self._printer_type = ptype
            self._printer_address = address
            self.printerConnected.emit(True)
            self.printerStatusChanged.emit("online")
            self._flush_pending()
        except Exception as e:
            print(f"Connect Error: {e}")
            self.printerConnected.emit(False)
            self.printerStatusChanged.emit("offline")

    @Slot()
    def _do_disconnect(self):
        if self._printer:
            try:
                self._printer.close()
            except:
                pass
        self._printer = None
        self.printerConnected.emit(False)
        self.printerStatusChanged.emit("offline")

    @Slot(dict)
    def _do_print(self, receipt_data):
        if not self._printer and self._printer_type != "bluetooth":
            self._queue_pending(receipt_data)
            self.printError.emit("Printer offline - queued")
            return
        
        self.printerStatusChanged.emit("printing")
        try:
            lines = self._format_receipt(receipt_data)
            
            if self._printer_type == "bluetooth" and BLEAK_AVAILABLE:
                # Raw BT print via bleak
                async def bt_print():
                    async with BleakClient(self._printer_address) as client:
                        for line in lines:
                            await client.write_gatt_char(
                                "00002a00-0000-1000-8000-00805f9b34fb",  # Generic write char - adjust for your printer
                                (line + "\n").encode('utf-8')
                            )
                asyncio.run(bt_print())
            else:
                # Network/USB print via escpos
                for line in lines:
                    self._printer.text(line + "\n")
                self._printer.cut()
            
            self.printSuccess.emit(receipt_data.get('sale_id', 'unknown'))
            self.printerStatusChanged.emit("online")
        except Exception as e:
            print(f"Print Error: {e}")
            self._queue_pending(receipt_data)
            self.printError.emit(str(e))
            self.printerStatusChanged.emit("offline")

    def _format_receipt(self, data):
        title = data.get('title', 'ANTIGRAVITY POS')
        store = data.get('store_name', 'My Store')
        currency = data.get('currency', 'TND')
        lines = [
            "",
            f"      {title}",
            "=" * 32,
            f"  {store}",
            "-" * 32,
            f"  SALE: {data.get('sale_id', 'N/A')}",
            f"  {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            "-" * 32,
            "  QTY  ITEM           PRICE",
        ]
        for item in data.get('items', []):
            name = item['name'][:14].ljust(14)
            lines.append(f"  {str(item['quantity']).ljust(3)}  {name}  {float(item['price']):.3f}")
        lines.extend([
            "-" * 32,
            f"  TOTAL:              {float(data['total']):.3f} {currency}",
            f"  QR: {data.get('qr_url', 'N/A')[:30]}",
            "=" * 32,
            "      THANK YOU!",
            ""
        ])
        return lines

    def _queue_pending(self, receipt_data):
        import json
        conn = sqlite3.connect(self.db_path)
        conn.execute("INSERT INTO pending_prints (receipt_data) VALUES (?)", 
                     (json.dumps(receipt_data),))
        conn.commit()
        conn.close()
        self._load_pending_count()

    def _flush_pending(self):
        if not self._printer and self._printer_type != "bluetooth":
            return
        import json
        conn = sqlite3.connect(self.db_path)
        rows = conn.execute("SELECT id, receipt_data FROM pending_prints ORDER BY created_at").fetchall()
        for row_id, data_json in rows:
            try:
                self._do_print(json.loads(data_json))
                conn.execute("DELETE FROM pending_prints WHERE id = ?", (row_id,))
                conn.commit()
            except Exception as e:
                print(f"Flush pending error: {e}")
                break
        conn.close()
        self._load_pending_count()

    def _load_pending_count(self):
        conn = sqlite3.connect(self.db_path)
        count = conn.execute("SELECT COUNT(*) FROM pending_prints").fetchone()[0]
        conn.close()
        self.pendingCountChanged.emit(count)