import json
import datetime
import hashlib
import os
import sqlite3

class ComplianceManager:
    @staticmethod
    def get_teif_payload(store_tax_id, total, sale_id):
        now = datetime.datetime.now()
        timestamp = now.strftime("%Y%m%d%H%M%S")
        
        raw_str = f"{store_tax_id}|{sale_id}|{total}|{timestamp}"
        iid = hashlib.sha256(raw_str.encode()).hexdigest().upper()[:16]
        
        qr_url = f"https://compliance.tn/verify?iid={iid}&total={total}"
        
        return {
            "iid": iid,
            "qr_url": qr_url,
            "timestamp": timestamp
        }


class _ComplianceWrapper:
    """Sync wrapper for root main.py"""
    _instance = None
    
    @classmethod
    def getInstance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance
    
    def get_next_iid(self):
        return ComplianceManager.get_teif_payload("TN123456", 0.0, 1)['iid']
    
    def generate_qr_data(self, iid, total, tax):
        return f"https://compliance.tn/verify?iid={iid}&total={total}"
    
    def save_invoice(self, iid, total, tax, qr_data, cart_items):
        import os
        base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        db_path = os.path.join(base_dir, "db", "antigravity.db")
        conn = sqlite3.connect(db_path)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        try:
            c.execute("INSERT INTO invoices (iid, total, tax, qr) VALUES (?, ?, ?, ?)", (iid, total, tax, qr_data))
            for item in cart_items:
                c.execute("UPDATE products SET stock = stock - ? WHERE id = ?", (item.get('quantity', 1), item['id']))
            conn.commit()
            return True
        except Exception as e:
            print(f"Error saving invoice: {e}")
            return False
        finally:
            conn.close()

Compliance = _ComplianceWrapper.getInstance()
