import threading
import time
from PySide6.QtCore import QObject, Signal, QThread

class ScannerWorker(QThread):
    barcode_scanned = Signal(str)

    def __init__(self, device_path="/dev/input/event0"):
        super().__init__()
        self.device_path = device_path
        self.enabled = True
        self.running = True

    def run(self):
        try:
            import evdev
            from evdev import InputDevice, categorize, ecodes
            device = InputDevice(self.device_path)
            device.grab() # Take exclusive control
            
            barcode = ""
            for event in device.read_loop():
                if not self.running: break
                if not self.enabled: continue
                
                if event.type == ecodes.EV_KEY:
                    data = categorize(event)
                    if data.keystate == 1: # Key down
                        key = data.keycode
                        if key == 'KEY_ENTER':
                            if barcode:
                                self.barcode_scanned.emit(barcode)
                                barcode = ""
                        else:
                            # Map keycodes to characters
                            char = str(key).replace('KEY_', '')
                            if len(char) == 1:
                                barcode += char
        except ImportError:
            print("Scanner error: evdev not found (likely running on non-Linux system). Hardware scanner disabled.")
            while self.running:
                time.sleep(1)
        except Exception as e:
            print(f"Scanner error: {e}")
            while self.running:
                time.sleep(1)

class Scanner(QObject):
    def __init__(self):
        super().__init__()
        self.worker = ScannerWorker()
        self.worker.barcode_scanned.connect(self._on_scanned)
        self.worker.start()

    def _on_scanned(self, barcode):
        print(f"Hardware Scanned: {barcode}")
        
    def set_enabled(self, enabled):
        self.worker.enabled = enabled
