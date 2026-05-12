In main.py, make these exact changes:

1. Replace: from printer import PrinterManager
   With: from printer import PrinterWorker

2. In POSBackend.__init__:
   - Replace: self.printer = PrinterManager()
   - Add:
        self.printer_thread = QThread()
        self.printer_worker = PrinterWorker()
        self.printer_worker.moveToThread(self.printer_thread)
        self.printer_thread.start()
        
        # Connect printer signals to UI
        self.printer_worker.printerStatusChanged.connect(self._on_printer_status)
        self.printer_worker.printSuccess.connect(self._on_print_success)
        self.printer_worker.printError.connect(self._on_print_error)
        self.printer_worker.printerDiscovered.connect(self._on_printer_discovered)
        self.printer_worker.pendingCountChanged.connect(self._on_pending_count)

3. Add new signals to POSBackend:
    printerStatusChanged = Signal(str)
    printerDiscovered = Signal(list)
    pendingCountChanged = Signal(int)
    printSuccess = Signal(str)
    printError = Signal(str)

4. Add handler methods:
    def _on_printer_status(self, status): self.printerStatusChanged.emit(status)
    def _on_print_success(self, sale_id): self.printSuccess.emit(sale_id)
    def _on_print_error(self, msg): self.printError.emit(msg)
    def _on_printer_discovered(self, devices): self.printerDiscovered.emit(devices)
    def _on_pending_count(self, count): self.pendingCountChanged.emit(count)

5. In checkout():
   - Replace: self.printer.print_receipt(receipt_data)
   - With: self.printer_worker.requestPrint.emit(receipt_data)

6. Add new slots:
    @Slot()
    def scanPrinters(self):
        self.printer_worker.requestScan.emit()
    
    @Slot(str, str)
    def connectPrinter(self, address, ptype):
        self.printer_worker.requestConnect.emit(address, ptype)

7. Add cleanup in a new shutdown method:
    @Slot()
    def shutdown(self):
        self.printer_worker.requestDisconnect.emit()
        self.printer_thread.quit()
        self.printer_thread.wait(3000)
        # Same for db_thread and scanner_thread if they exist

8. Connect app aboutToQuit to shutdown:
    app.aboutToQuit.connect(backend.shutdown)