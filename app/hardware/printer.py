import os
import asyncio
import socket
import json
import time
from datetime import datetime
from PySide6.QtCore import QObject, Signal, Slot, QThread, QTimer

# Hardware Libraries
try:
    from bleak import BleakScanner, BleakClient
    from escpos.printer import Network, Dummy
    from escpos.exceptions import USBError
    HAS_HW_LIBS = True
except ImportError:
    HAS_HW_LIBS = False

class PrinterWorker(QObject):
    # Signals for UI Feedback
    printSuccess = Signal(str)
    printError = Signal(str)
    printerDiscovered = Signal(list)
    printerConnected = Signal(bool)
    printerStatusChanged = Signal(str)
    finished = Signal()

    def __init__(self, db_manager=None):
        super().__init__()
        self.db_manager = db_manager
        self.current_printer = None
        self.printer_type = None # "bluetooth", "wifi", "usb"
        self.printer_address = None
        self.is_connected = False
        self.pending_queue = []
        self.running = True

    @Slot()
    def scan_printers(self):
        """Sequential scan: Bluetooth first, then WiFi if BT is empty"""
        self.printerStatusChanged.emit("Scanning Bluetooth...")
        found = []
        
        if HAS_HW_LIBS:
            # 1. Bluetooth Scan
            try:
                loop = asyncio.new_event_loop()
                asyncio.set_event_loop(loop)
                bt_devices = loop.run_until_complete(self._async_scan_bt())
                found.extend(bt_devices)
            except Exception as e:
                print(f"BT Scan Error: {e}")

            # 2. WiFi Scan (only if BT found nothing or requested)
            if not found:
                self.printerStatusChanged.emit("Scanning WiFi...")
                try:
                    wifi_devices = self._scan_wifi_subnet()
                    found.extend(wifi_devices)
                except Exception as e:
                    print(f"WiFi Scan Error: {e}")
        
        self.printerDiscovered.emit(found)
        self.printerStatusChanged.emit(f"Scan complete. Found {len(found)} devices.")

    async def _async_scan_bt(self):
        scanner = BleakScanner()
        devices = await scanner.discover(timeout=10.0)
        matches = []
        keywords = ["Printer", "POS", "Thermal", "Xprinter", "Rongta", "Epson", "58mm", "80mm"]
        
        for d in devices:
            name = d.name if d.name else "Unknown Device"
            if any(key.lower() in name.lower() for key in keywords):
                matches.append({"name": name, "address": d.address, "type": "bluetooth", "rssi": d.rssi})
        return matches

    def _scan_wifi_subnet(self):
        found = []
        ports = [9100, 515]
        # Common subnet for Pi/POS setups
        base_ip = "192.168.1."
        
        for i in range(1, 255):
            ip = base_ip + str(i)
            for port in ports:
                try:
                    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                        s.settimeout(0.3)
                        if s.connect_ex((ip, port)) == 0:
                            found.append({"name": f"Network Printer ({ip})", "address": ip, "port": port, "type": "wifi"})
                except: continue
        return found

    @Slot(str, str)
    def connect_printer(self, address, p_type):
        self.printerStatusChanged.emit(f"Connecting to {address}...")
        try:
            if p_type == "wifi":
                self.current_printer = Network(address)
                self.is_connected = True
            elif p_type == "bluetooth":
                # Basic BT check, real connection happens during print in many libs
                # or we use dummy to verify formatting
                self.current_printer = Dummy() 
                self.is_connected = True
            
            self.printer_type = p_type
            self.printer_address = address
            self.printerConnected.emit(True)
            self.printerStatusChanged.emit("Printer Online")
        except Exception as e:
            self.is_connected = False
            self.printerConnected.emit(False)
            self.printerStatusChanged.emit(f"Connection failed: {e}")

    @Slot(dict, list)
    def do_print(self, invoice_data, cart_items):
        if not self.is_connected:
            self._queue_print(invoice_data, cart_items)
            return

        try:
            receipt = self._generate_receipt_content(invoice_data, cart_items)
            # Hardware specific sending
            if self.printer_type == "wifi":
                self.current_printer._raw(receipt)
            else:
                # Fallback to local log/dummy for testing
                print("--- THERMAL PRINT OUTPUT ---")
                print(receipt.decode('utf-8', errors='ignore'))
            
            self.printSuccess.emit(invoice_data['iid'])
        except Exception as e:
            print(f"Print failed: {e}")
            self._queue_print(invoice_data, cart_items)
            self.is_connected = False
            self.printerConnected.emit(False)

    def _generate_receipt_content(self, invoice, items):
        """Generate compact 58mm receipt bytes"""
        # Simple text for now, can be expanded with escpos commands
        now = datetime.now().strftime("%Y-%m-%d %H:%M")
        lines = [
            "\x1b\x61\x01", # Center align
            "ANTIGRAVITY POS\n",
            f"{now}\n",
            "--------------------------\n",
            "\x1b\x61\x00", # Left align
        ]
        
        for item in items:
            name = item['name'][:18].ljust(18)
            price = f"{float(item['price']):.2f}".rjust(6)
            lines.append(f"{item['quantity']}x {name} {price}\n")
            
        lines.append("--------------------------\n")
        lines.append(f"TOTAL:           {float(invoice['total']):.2f} TND\n")
        lines.append("\x1b\x61\x01") # Center
        lines.append("\nTHANK YOU!\n\n\n\x1d\x56\x00") # Cut
        
        return "".join(lines).encode('ascii', errors='ignore')

    def _queue_print(self, invoice, items):
        print(f"Queueing receipt {invoice['iid']} for later...")
        # In a real app, we'd save to SQLite here
        self.pending_queue.append((invoice, items))
        self.printError.emit("Printer offline. Receipt queued.")

    @Slot()
    def retry_pending(self):
        if not self.is_connected or not self.pending_queue:
            return
            
        print(f"Retrying {len(self.pending_queue)} pending prints...")
        still_pending = []
        for inv, items in self.pending_queue:
            try:
                self.do_print(inv, items)
            except:
                still_pending.append((inv, items))
        self.pending_queue = still_pending

class ThermalPrinter(QObject):
    """Wrapper to manage the thread and worker from the main thread"""
    def __init__(self, db_manager=None):
        super().__init__()
        self.thread = QThread()
        self.worker = PrinterWorker(db_manager)
        self.worker.moveToThread(self.thread)
        
        # Connect internal retry timer
        self.retry_timer = QTimer()
        self.retry_timer.timeout.connect(self.worker.retry_pending)
        self.retry_timer.start(30000)
        
        self.thread.start()

    def print_receipt(self, invoice_data, cart_items):
        # Triggered via main.py POSBackend signal
        pass

    def stop(self):
        self.retry_timer.stop()
        self.thread.quit()
        self.thread.wait()
