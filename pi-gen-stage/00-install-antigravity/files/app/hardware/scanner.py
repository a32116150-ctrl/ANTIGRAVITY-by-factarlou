import time
from PySide6.QtCore import QObject, Signal, Slot, QThread

class ScannerWorker(QObject):
    barcode_scanned = Signal(str)
    finished = Signal()

    def __init__(self, device_path="/dev/input/event0"):
        super().__init__()
        self.device_path = device_path
        self.enabled = True
        self.running = True

    @Slot()
    def process(self):
        try:
            import evdev
            from evdev import InputDevice, categorize, ecodes
            device = InputDevice(self.device_path)
            device.grab()
            
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
                            char = str(key).replace('KEY_', '')
                            if len(char) == 1:
                                barcode += char
        except Exception as e:
            print(f"Scanner error: {e}")
            while self.running:
                time.sleep(1)
        self.finished.emit()

    @Slot()
    def stop(self):
        self.running = False

class Scanner(QObject):
    request_set_enabled = Signal(bool)
    barcode_received = Signal(str)

    def __init__(self):
        super().__init__()
        self.thread = QThread()
        self.worker = ScannerWorker()
        self.worker.moveToThread(self.thread)
        
        self.thread.started.connect(self.worker.process)
        self.worker.barcode_scanned.connect(self.barcode_received)
        self.worker.finished.connect(self.thread.quit)
        
        self.request_set_enabled.connect(self.set_enabled_slot)
        self.thread.start()

    @Slot(bool)
    def set_enabled_slot(self, enabled):
        self.worker.enabled = enabled

    def stop(self):
        self.worker.stop()
        self.thread.quit()
        self.thread.wait()
