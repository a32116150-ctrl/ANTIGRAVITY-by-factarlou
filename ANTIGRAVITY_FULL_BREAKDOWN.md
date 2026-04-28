# 🌌 Antigravity POS: Full Project Breakdown

Antigravity is a high-performance, industrial-grade Point of Sale (POS) system engineered specifically for the Raspberry Pi Zero 2 W. It combines a robust Python backend with a premium, hardware-accelerated Qt6/QML frontend.

---

## 🏛️ 1. System Architecture

The application follows a **Controller-View-Model (CVM)** architecture, optimized for embedded systems:

### A. The Backend (Python 3.10+)
The backend acts as the "Brain" of the system. It handles:
*   **Hardware Communication**: Interfaces with USB/Serial thermal printers and HID barcode scanners.
*   **Data Persistence**: A high-speed SQLite database with optimized indexing for product searches.
*   **Fiscal Engine**: Calculates taxes, generates unique invoice IDs (IID), and prepares QR data for tax compliance.
*   **Bridge Layer**: Uses PySide6 (Qt for Python) to expose real-time data to the UI via Signals and Slots.

### B. The Frontend (Qt Quick / QML)
The UI is built for speed and touch-interaction:
*   **Modern Light Theme**: A curated aesthetic using `#F8F9FB` backgrounds, `#7C3AED` (Purple) accents, and soft elevation shadows.
*   **Reactive Layouts**: The UI automatically adapts between Full HD (1920x1080) and smaller 7-inch Raspberry Pi displays.
*   **Component-Based**: Every UI element (Button, Card, Input) is a reusable component, ensuring visual consistency.

---

## 📂 2. File Hierarchy & Manifest

### Core Files
*   `main.py`: The entry point. Initializes the QML engine, instantiates the backend, and manages the application lifecycle.
*   `requirements.txt`: Python dependencies (PySide6, etc.).

### `app/` (Business Logic)
*   `database.py`: Manages the SQLite schema and queries. Includes a "Never-None" policy to prevent runtime crashes.
*   `compliance.py`: Handles fiscal logic, VAT calculations, and unique ID generation.
*   `printer.py`: Low-level driver for ESC/POS thermal printers.
*   `hardware/scanner.py`: Manages barcode scanner input via `evdev` (Linux) with a fallback mode for macOS development.

### `ui/` (Presentation)
*   `main.qml`: The master shell containing the Sidebar and View Loader.
*   `SalesView.qml`: The primary terminal. Features a product grid, category pills, and a real-time order summary.
*   `InventoryView.qml`: Stock management interface with product CRUD (Create, Read, Update, Delete) capability.
*   `DashboardView.qml`: Real-time analytics showing daily revenue, transaction counts, and low-stock alerts.
*   `components/`: Reusable UI elements like `NeonButton.qml`, `NeonCard.qml`, and `NeonTextField.qml`.
*   `styles/NeonStyle.qml`: The **Single Source of Truth** for the design system (colors, fonts, spacing).

### `buildroot/` (OS Engineering)
*   `configs/antigravity_defconfig`: The blueprint for the custom Linux OS. It tells Buildroot which drivers and packages to include for the RPi Zero 2 W.
*   `board/antigravity/`: Contains post-build scripts that optimize the OS for fast booting (under 10 seconds).

---

## 🔌 3. Hardware Integration

### Barcode Scanner
*   **Technology**: `evdev` (Event Device) integration.
*   **Function**: Captures raw keyboard events from the USB scanner and parses them into product IDs.
*   **Fallback**: On non-Linux systems, it operates in "Simulator Mode" to allow development without hardware.

### Thermal Printer
*   **Standard**: ESC/POS.
*   **Logic**: Generates a formatted text receipt with a compliance header, itemized list, and a footer with date/time.

### Raspberry Pi Zero 2 W
*   **OS**: Custom-built Buildroot Linux (No Desktop Environment, just the app).
*   **Display**: Optimized for HDMI and 40-pin RGB displays.

---

## 🏗️ 4. The Release Pipeline (CI/CD)

The project uses **GitHub Actions** to automate the creation of hardware images:
1.  **Trigger**: Pushing a version tag (e.g., `v1.0.1`) to GitHub.
2.  **Compilation**: A high-power cloud runner clones Buildroot, applies the `antigravity_defconfig`, and compiles the entire OS.
3.  **Artifact**: It outputs a compressed `sdcard.img` file.
4.  **Deployment**: The image is attached to a GitHub Release, ready to be flashed using BalenaEtcher.

---

## 🎨 5. Design System Tokens

| Token | Value | Purpose |
| :--- | :--- | :--- |
| **Primary** | `#7C3AED` | Brand Color (Buttons, Active Icons) |
| **Background**| `#F8F9FB` | Main app background (Light Mode) |
| **Surface** | `#FFFFFF` | Card and Panel background |
| **Text Main** | `#0F172A` | Primary readability (Slate 900) |
| **Radius M** | `16px` | Standard corner rounding |
| **Shadow** | `DropShadow` | Provides depth without heavy borders |

---

## 🛠️ 6. Technical Implementation Details
*   **Thread Safety**: Hardware interactions (printing/scanning) are offloaded to background threads to ensure the UI remains smooth at 60fps.
*   **Memory Footprint**: The custom OS is under 150MB, and the app consumes less than 80MB of RAM, making it perfect for the 512MB limit of the Pi Zero 2 W.

---

## 🚀 7. State Update (v1.2.x Series)
### **UI & Core Logic Features**
* **Stock Guard**: Added strict stock validation during checkout. Negative quantities are blocked with a warning dialog.
* **Dashboard Live Metrics**: The dashboard now listens to `posBackend.dailySummaryChanged` via QML `Connections` to update Revenue/VAT/Transaction stats instantly after every sale.
* **Stock Alerts UI**: Fixed the "LOW STOCK" alert cards layout clipping issues. Replaced transparent hex values (`#EF444412`) which Qt incorrectly parsed, with solid colors (Red for empty, Amber for low) and crisp white text.
* **Reports View**: Fully implemented. Now displays a robust 100-invoice history table (ID, Date, VAT, Total), live today's stats, and buttons for Z-Report & Refresh.
* **Branding**: App is strictly branded as `ANTIGRAVITY by factarlou`.

### **CI/CD Architecture Rewrite**
The legacy `Buildroot` workflow (which caused 6-hour OOM failures) has been completely replaced by a robust two-stage pipeline:
1. **Job 1: App Installer Zip (~2 mins)**: Validates Python syntax and builds an app zip + a 1-click `install.sh` for folks flashing a stock Pi image.
2. **Job 2: RPi OS Image Builder (~30 mins)**: Uses the official `usimd/pi-gen-action` to compile the app directly into a bootable Debian OS `.img.xz` file.
   * *Critical Bug Fix (`v1.2.3 / v1.2.4`)*: GitHub Actions' `ubuntu-latest` (Ubuntu 24.04) has broken AppArmor `qemu-user-static` profiles. This was causing instant (45-second) Docker crashes. **Fix:** Downgraded the GitHub runner to `ubuntu-22.04` and explicitly added `docker/setup-qemu-action@v3` to securely register ARM binfmt handlers on the host before running the OS compilation.
   * *pi-gen Syntax*: Custom stages must be passed strictly as folder names (e.g., `pi-gen-stage` instead of `./pi-gen-stage`), must contain the `EXPORT_IMAGE` marker, and must explicitly receive the GitHub tag via `sed` since Docker isolation drops external environment variables.
