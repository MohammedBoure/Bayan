#!/usr/bin/env python3
"""
Bayan License Key Generator CLI (مُوَلِّدُ مَفَاتِيحِ تَرْخِيصِ بَيَان - سَطْرُ الأَوَامِرِ)
Command-line license generator using HMAC-SHA256.

Usage:
    python keygen.py
    python keygen.py BYN-XXXX-XXXX-XXXX
"""

import sys
import hmac
import hashlib

MASTER_SECRET = b'BAYAN_PRIMARY_ARABIC_2026_MASTER_SECRET_KEY'


def generate_activation_key(device_code: str) -> str:
    clean_device = device_code.strip().upper()
    if not clean_device:
        return ""
    
    digest = hmac.new(MASTER_SECRET, clean_device.encode('utf-8'), hashlib.sha256).hexdigest().upper()
    b1 = digest[0:4]
    b2 = digest[4:8]
    b3 = digest[8:12]
    b4 = digest[12:16]
    return f"ACT-{b1}-{b2}-{b3}-{b4}"


def main():
    print("=" * 60)
    print("   بُسْتَانُ النَّحْوِ العَرَبِيِّ - مُوَلِّدُ كَوْدِ التَّفْعِيلِ (Keygen)")
    print("=" * 60)

    if len(sys.argv) > 1:
        device_code = sys.argv[1]
    else:
        try:
            device_code = input("أَدْخِلْ كَوْدَ الجِهَازِ (Device Code): ").strip()
        except (KeyboardInterrupt, EOFError):
            print("\nإلغاء.")
            return

    if not device_code:
        print("خطأ: لم يتم إدخال كود الجهاز.")
        sys.exit(1)

    activation_key = generate_activation_key(device_code)
    print("\n------------------------------------------------------------")
    print(f" كَوْدُ الجِهَازِ:     {device_code.upper()}")
    print(f" كَوْدُ التَّفْعِيلِ:   {activation_key}")
    print("------------------------------------------------------------")
    print("أرسل كود التفعيل أعلاه إلى المستخدم لتنشيط البرنامج بصفة دائمة.\n")


if __name__ == "__main__":
    main()
