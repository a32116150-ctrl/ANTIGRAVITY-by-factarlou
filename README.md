# 🌌 Antigravity POS v1.5

**Antigravity** is a professional, industrial-grade Point of Sale (POS) system designed specifically for the **Raspberry Pi Zero 2 W**. It features a GPU-accelerated Qt6/QML frontend and a robust Python backend, optimized for speed, stability, and premium aesthetics.

---

## ✨ What's New in v1.5 (The Premium Update)

The project has undergone a complete transformation to meet modern industrial design standards.

### 🎨 Premium Light UI
*   **Modern Aesthetics**: Transitioned from a dark "Neon" look to a clean, "Premium Light" theme featuring soft shadows, high-contrast typography, and a refined Slate/Purple color palette.
*   **Interactive Product Grid**: Entire product cards are now clickable with a snappy "Pulse" animation for better touch feedback.
*   **Enhanced Navigation**: Redesigned sidebar and header for intuitive view switching between Sales, Inventory, and Analytics.

### 🚀 Stability & Performance
*   **QML Optimization**: Refactored data bindings to prevent lag on the Raspberry Pi's hardware.
*   **Thread Safety**: Hardened the backend to ensure hardware threads (Scanner/Printer) close gracefully, resolving previous "Abort 134" errors.
*   **Never-None Policy**: Implemented a strict data safety layer in the database to prevent crashes during tax and total calculations.

---

## 🛠️ GitHub Pipeline Recovery (The "Kernel 404" Fix)

During the transition to v1.5, the automated GitHub Actions build pipeline encountered a critical failure that prevented the creation of the SD card image.

*   **The Technical Problem**: Buildroot (our OS compiler) was configured to download the Raspberry Pi Linux Kernel from a specific file link. However, that file was moved or renamed by the Raspberry Pi team, leading to a **404 Not Found** error during the download stage.
*   **The Analogy**: It was like having an old address for a friend—GitHub was knocking on the door, but nobody was home.
*   **The Fix**: We updated the `antigravity_defconfig` to point to the stable, official `rpi-6.1.y` kernel branch. This provided GitHub with the correct "new address," ensuring the build system can always find the necessary software.
*   **Long-term Stability**: By linking to an active branch rather than a static file, the pipeline is now "future-proofed" against minor repository changes.

---

## 📂 Project Documentation

For deeper technical details, please refer to:
*   [**Full Technical Breakdown**](./ANTIGRAVITY_FULL_BREAKDOWN.md): A detailed manifest of every file, function, and hardware driver.
*   [**Technical README**](./README_TECH.md): Developer guide for local setup and environment configuration.

---

## 🚀 Getting Started

### Local Development (Mac/Linux/Windows)
1.  Install dependencies:
    ```bash
    pip install -r requirements.txt
    ```
2.  Run the application:
    ```bash
    python main.py
    ```

### Hardware Deployment (Raspberry Pi Zero 2 W)
1.  Download the latest `sdcard.img` from the [Releases](https://github.com/a32116150-ctrl/ANTIGRAVITY-by-factarlou/releases) page.
2.  Flash the image to a microSD card using **BalenaEtcher**.
3.  Insert into your Pi and power on. The app will boot directly into the Dashboard in under 10 seconds.

---

## 🔌 Hardware Support
*   **Barcode Scanner**: Automatic HID detection (Simulator mode for non-Linux).
*   **Thermal Printer**: ESC/POS USB/Serial support.
*   **Display**: Optimized for 7" Touchscreens and HDMI displays.

---

© 2026 Factarlou. Built with ❤️ for the future of retail.
