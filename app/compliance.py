"""
app/compliance.py — Fiscal Compliance Engine
=============================================
Multi-market, pluggable compliance layer.

For each market, you can:
  1. Override the QR URL template in Settings ("compliance_url_template")
  2. Set a custom store_tax_id in Settings

The default behavior is market-agnostic: generates a locally-verifiable
SHA-256 hash IID. The QR URL can point to any verification endpoint.
"""

import json
import datetime
import hashlib
import os
import sqlite3


class ComplianceManager:
    """
    Stateless compliance utility.
    Generates unique Invoice IDs (IID) and QR verification URLs.

    The IID algorithm is deliberately simple and reproducible:
    SHA-256(tax_id|sale_id|total|timestamp) → first 16 hex chars.

    To adapt for a specific country's e-invoicing standard,
    subclass this and override `get_payload()`.
    """

    @staticmethod
    def get_payload(store_tax_id: str, total: float, sale_id, qr_url_template: str = "") -> dict:
        """
        Build a compliance payload for an invoice.

        Args:
            store_tax_id:     Merchant's tax identifier (any format)
            total:            Invoice total (before tax)
            sale_id:          Sequential or UUID sale identifier
            qr_url_template:  URL template with {iid} and {total} placeholders.
                              If empty, uses a generic local format.

        Returns:
            dict with keys: iid, qr_url, timestamp
        """
        now = datetime.datetime.now()
        timestamp = now.strftime("%Y%m%d%H%M%S")

        raw_str = f"{store_tax_id}|{sale_id}|{total}|{timestamp}"
        iid = hashlib.sha256(raw_str.encode()).hexdigest().upper()[:16]

        if qr_url_template:
            try:
                qr_url = qr_url_template.format(iid=iid, total=total, tax_id=store_tax_id)
            except KeyError:
                qr_url = f"{qr_url_template}?iid={iid}&total={total}"
        else:
            # Generic fallback — no external dependency
            qr_url = f"POS:{store_tax_id}:{iid}:{total:.3f}"

        return {
            "iid": iid,
            "qr_url": qr_url,
            "timestamp": timestamp,
        }


class _ComplianceWrapper:
    """
    Sync wrapper for use from main.py POSBackend.
    Reads compliance settings from the database on each call
    so that store settings changes take effect immediately.
    """
    _instance = None

    @classmethod
    def getInstance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def _get_db_path(self):
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        return os.path.join(base_dir, "db", "antigravity.db")

    def _read_settings(self):
        """Read relevant settings directly from SQLite."""
        try:
            conn = sqlite3.connect(self._get_db_path())
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                "SELECT key, value FROM settings WHERE key IN "
                "('store_tax_id', 'compliance_url_template')"
            ).fetchall()
            conn.close()
            return {r["key"]: r["value"] for r in rows}
        except Exception:
            return {}

    def get_next_iid(self) -> str:
        settings = self._read_settings()
        tax_id = settings.get("store_tax_id", "UNKNOWN")
        payload = ComplianceManager.get_payload(tax_id, 0.0, "init")
        return payload["iid"]

    def generate_qr_data(self, iid: str, total: float, tax: float) -> str:
        settings = self._read_settings()
        tax_id = settings.get("store_tax_id", "UNKNOWN")
        template = settings.get("compliance_url_template", "")
        payload = ComplianceManager.get_payload(tax_id, total, iid, template)
        return payload["qr_url"]

    def save_invoice(self, iid, total, tax, qr_data, cart_items):
        """Persist invoice + update stock. Returns True on success."""
        try:
            conn = sqlite3.connect(self._get_db_path())
            conn.row_factory = sqlite3.Row
            c = conn.cursor()
            c.execute(
                "INSERT INTO invoices (iid, total, tax, qr) VALUES (?, ?, ?, ?)",
                (iid, total, tax, qr_data)
            )
            for item in cart_items:
                c.execute(
                    "UPDATE products SET stock = stock - ? WHERE id = ?",
                    (item.get("quantity", 1), item["id"])
                )
            conn.commit()
            return True
        except Exception as e:
            print(f"[Compliance] Error saving invoice: {e}")
            return False
        finally:
            conn.close()


Compliance = _ComplianceWrapper.getInstance()
