# Antigravity POS: Technical Architecture & Implementation Details

Antigravity POS is a high-performance, industrial-grade Point of Sale system designed specifically for the **Raspberry Pi Zero 2 W**, and currently ported to **macOS** for development and testing. It utilizes a **Never-None Data Policy** and a **Synchronized GridLayout** to ensure 100% data integrity and pixel-perfect alignment.

---

## 🏛️ System Architecture

### 1. The Core (Python + PySide6)
The application follows a **Decoupled Controller Pattern**. The logic is handled by a `POSBackend` (QObject) which acts as a bridge between the SQLite database and the QML UI.

- **Thread-Safe Workers**: All database operations run on a dedicated `DatabaseWorker` thread. This prevents UI stuttering during heavy I/O (critical for the Pi Zero's limited CPU).
- **WAL Mode Persistence**: SQLite is initialized in **Write-Ahead Logging (WAL)** mode. This allows concurrent reads and writes, ensuring that a large inventory search never blocks a sale recording.

### 2. The Frontend (QtQuick/QML)
The UI is built using a custom **Neon Industrial** design system.
- **Glassmorphism**: High-contrast dark backgrounds (`#0A0F1A`) with vibrant cyan and magenta highlights.
- **Micro-Animations**: Hover effects and state transitions provide a premium feel.
- **Hardware Protection**: Interactive elements like the "Checkout" button include a **300ms cooldown timer** to prevent accidental double-clicks on touch hardware.

---

## 📐 Solutions to Critical Challenges

### ⛓️ The "Column Drift" Resolution (Synchronized GridLayout)
The most significant UI challenge was the misalignment of the inventory table. As product names varied in length, columns for Barcode, Stock, and Price would shift.

**The Fix:** We implemented a **Strict Width Locking** strategy:
- **Unified Grid Logic**: Both the `Table Header` and the `List Delegate` use the exact same `GridLayout` configuration.
- **Anchor Columns**: Barcode (150px), Stock (100px), Price (120px), and Actions (100px) are locked.
- **Flexible Space**: Only the "Product Name" column is allowed to fill the remaining width (`Layout.fillWidth: true`).
- **Result**: Data is mathematically guaranteed to align perfectly under its header, regardless of name length.

### 🛡️ The "Never-None" Data Policy
To prevent crashes on low-resource hardware, the database layer implements a **Total Null-Safety** protocol using SQLite's `IFNULL` at the query level.
```sql
SELECT IFNULL(name, 'Unknown'), IFNULL(price, 0.0), IFNULL(stock, 0) ...
```
This ensures that the QML engine always receives a valid data type, eliminating "Undefined" or "Null" property errors in the UI.

---

## 🔌 Hardware Simulation (macOS Port)

Since physical ESC/POS printers and `evdev` scanners are Linux-only, the macOS version uses an **Abstraction Layer**:

- **Simulated Scanner**: A hidden `TextField` in `SalesView.qml` captures keyboard wedge input. Focus is programmatically managed to ensure the scanner is always "active" when needed.
- **Simulated Printer**: The `PrinterManager` generates `.txt` receipts in the `receipts/` directory and triggers the macOS `open` command to display them instantly in the default text viewer.
- **Logic Integration**: Unlike simple clearing, the **Checkout** logic performs an atomic database update to decrement stock lev![alt text](https://file%2B.vscode-resource.vscode-cdn.net/var/folders/bj/7vx5pp195kx82vjwksbc9w3m0000gn/T/TemporaryItems/NSIRD_screencaptureui_laHVGQ/Screenshot%202026-04-22%20at%205.59.24%E2%80%AFAM.png?version%3D1776834038981)els in the `products` table upon every successful sale.

---

## 📁 Project Structure

- **`app/main.py`**: Entry point & QML Context Bridge.
- **`app/database.py`**: Threaded SQLite manager with WAL & CRUD logic.
- **`app/scanner.py` & `app/printer.py`**: Hardware abstraction interfaces.
- **`ui/main.qml`**: Shell with 1024x768 resolution & ColumnLayout anchoring.
- **`ui/SalesView.qml`**: Dashboard with Category Tabs, Product Grid, and Live Cart.
- **`ui/InventoryView.qml`**: Management view with Synchronized GridLayout and CRUD Dialogs.
- **`ui/styles/NeonStyle.qml`**: Global singleton for design tokens (Colors, Fonts).

---

## ⚙️ Maintenance & Scaling
- **Adding Products**: Use the `+ ADD PRODUCT` dialog in the Inventory section.
- **Category Management**: Categories are handled as unique entities. Adding a category automatically updates the filter bars in both Sales and Inventory views.
- **Low Stock Alerts**: Managed via `low_stock_threshold`. Items below this level turn **Neon Magenta** automatically.

---

## 🚀 Release & Deployment (CI/CD)

The project uses a high-performance **GitHub Actions** pipeline to produce production-ready OS images.

### 1. App Installer (ZIP)
Generates a lightweight ZIP containing the app source and a one-click `install.sh` for users running a stock Raspberry Pi OS.

### 2. Full OS Image (pi-gen)
Compiles a custom, bootable **Raspberry Pi OS Lite (64-bit)** image.
- **Build Engine**: `pi-gen` (official RPi Foundation build tool).
- **Runner**: Ubuntu 22.04 (optimized for QEMU/Docker stability).
- **Custom Stage**: The `pi-gen-stage` folder integrates the app directly into `/opt/antigravity`, pre-configures the `pi` user, and sets up the `antigravity.service` for instant boot-to-app behavior.
- **Reliability**: Features a multi-stage GPG keyring fix to ensure Debian Bookworm archives are correctly validated during headless builds.

> [!NOTE]
> Deployment images are optimized for **Raspberry Pi Zero 2 W** but compatible with Pi 3, 4, and 5.

> [!NOTE]
> This system is optimized for **800x480** (Raspberry Pi Official Touch) but scales perfectly up to **1024x768** and beyond due to its flexible grid architecture.
