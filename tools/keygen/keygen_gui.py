#!/usr/bin/env python3
"""
Bayan License Key Generator GUI (مُوَلِّدُ مَفَاتِيحِ تَرْخِيصِ بَيَان)
Generates permanent activation keys from unique device codes using HMAC-SHA256.
Requires no external dependencies (uses standard Python library: tkinter, hmac, hashlib).
"""

import hmac
import hashlib
import tkinter as tk
from tkinter import messagebox

# Master Secret Key (MUST match masterSecret in lib/services/license_service.dart)
MASTER_SECRET = b'BAYAN_PRIMARY_ARABIC_2026_MASTER_SECRET_KEY'


def generate_activation_key(device_code: str) -> str:
    """Computes the HMAC-SHA256 activation key for a given device code."""
    clean_device = device_code.strip().upper()
    if not clean_device:
        return ""
    
    digest = hmac.new(MASTER_SECRET, clean_device.encode('utf-8'), hashlib.sha256).hexdigest().upper()
    b1 = digest[0:4]
    b2 = digest[4:8]
    b3 = digest[8:12]
    b4 = digest[12:16]
    return f"ACT-{b1}-{b2}-{b3}-{b4}"


class KeygenApp(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("Bayan License Key Generator | مُوَلِّدُ مَفَاتِيحِ تَرْخِيصِ بَيَان")
        self.geometry("580x420")
        self.minsize(540, 380)
        self.configure(bg="#F8FAFC")

        self._setup_ui()

    def _setup_ui(self):
        # Header banner
        header = tk.Frame(self, bg="#00796B", pady=16)
        header.pack(fill=tk.X)

        title = tk.Label(
            header,
            text="بُسْتَانُ النَّحْوِ العَرَبِيِّ - مُوَلِّدُ كَوْدِ التَّفْعِيلِ",
            font=("Segoe UI", 16, "bold"),
            fg="white",
            bg="#00796B",
        )
        title.pack()

        subtitle = tk.Label(
            header,
            text="Bayan License Keygen (HMAC-SHA256 Administrator Tool)",
            font=("Segoe UI", 10),
            fg="#E0F2F1",
            bg="#00796B",
        )
        subtitle.pack()

        # Content frame
        content = tk.Frame(self, bg="#F8FAFC", padx=30, pady=20)
        content.pack(fill=tk.BOTH, expand=True)

        # Device Code Input
        lbl_device = tk.Label(
            content,
            text="1. أَدْخِلْ كَوْدَ الجِهَازِ (Device Code):",
            font=("Segoe UI", 12, "bold"),
            fg="#0F172A",
            bg="#F8FAFC",
            anchor="w",
        )
        lbl_device.pack(fill=tk.X, pady=(0, 6))

        self.txt_device = tk.Entry(
            content,
            font=("Consolas", 14, "bold"),
            fg="#004D40",
            bg="white",
            relief=tk.SOLID,
            bd=1,
            justify="center",
        )
        self.txt_device.pack(fill=tk.X, ipady=8, pady=(0, 16))
        self.txt_device.focus()
        self.txt_device.bind("<Return>", lambda event: self.on_generate())

        # Generate Button
        btn_generate = tk.Button(
            content,
            text="🔑 تَوْلِيدُ كَوْدِ التَّفْعِيلِ الدَّائِمِ (Generate Key)",
            font=("Segoe UI", 12, "bold"),
            bg="#00796B",
            fg="white",
            activebackground="#004D40",
            activeforeground="white",
            cursor="hand2",
            relief=tk.FLAT,
            command=self.on_generate,
        )
        btn_generate.pack(fill=tk.X, ipady=8, pady=(0, 20))

        # Activation Key Output
        lbl_key = tk.Label(
            content,
            text="2. كَوْدُ التَّفْعِيلِ النَّاتِجُ (Activation Key):",
            font=("Segoe UI", 12, "bold"),
            fg="#0F172A",
            bg="#F8FAFC",
            anchor="w",
        )
        lbl_key.pack(fill=tk.X, pady=(0, 6))

        key_frame = tk.Frame(content, bg="#F8FAFC")
        key_frame.pack(fill=tk.X)

        self.txt_key = tk.Entry(
            key_frame,
            font=("Consolas", 15, "bold"),
            fg="#1565C0",
            bg="#E2E8F0",
            relief=tk.SOLID,
            bd=1,
            justify="center",
            state="readonly",
        )
        self.txt_key.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=8)

        btn_copy = tk.Button(
            key_frame,
            text="📋 نَسْخ",
            font=("Segoe UI", 11, "bold"),
            bg="#EF6C00",
            fg="white",
            activebackground="#E65100",
            activeforeground="white",
            cursor="hand2",
            relief=tk.FLAT,
            padx=16,
            command=self.on_copy,
        )
        btn_copy.pack(side=tk.RIGHT, ipady=6, padx=(8, 0))

        # Status Footer
        self.lbl_status = tk.Label(
            self,
            text="جاهز. أدخل كود الجهاز ثم اضغط توليد.",
            font=("Segoe UI", 10),
            fg="#64748B",
            bg="#F8FAFC",
            pady=10,
        )
        self.lbl_status.pack(side=tk.BOTTOM)

    def on_generate(self):
        device_code = self.txt_device.get().strip()
        if not device_code:
            messagebox.showwarning("تنبيه", "يرجى إدخال كود الجهاز أولاً (Device Code)!")
            return

        key = generate_activation_key(device_code)
        self.txt_key.config(state="normal")
        self.txt_key.delete(0, tk.END)
        self.txt_key.insert(0, key)
        self.txt_key.config(state="readonly")

        # Auto copy to clipboard for convenience
        self.clipboard_clear()
        self.clipboard_append(key)
        self.lbl_status.config(
            text=f"✓ تم توليد كود التفعيل ({key}) ونسخه تلقائياً للحافظة!",
            fg="#16A34A",
        )

    def on_copy(self):
        key = self.txt_key.get().strip()
        if not key:
            messagebox.showinfo("تنبيه", "قم بتوليد الكود أولاً لنسخه.")
            return
        self.clipboard_clear()
        self.clipboard_append(key)
        self.lbl_status.config(text="✓ تم نسخ كود التفعيل للحافظة بنجاح!", fg="#16A34A")


if __name__ == "__main__":
    app = KeygenApp()
    app.mainloop()
