# License Keygen Tools Directory (`tools/keygen`)

This directory contains standalone administrator tools used exclusively by the software author/developer to generate permanent activation keys for client devices.

## How the Licensing System Works:
1. **Device Identification**: The client runs the application on their Windows machine, which generates a unique hardware identifier (e.g., `BYN-675B-A8C1-7BFB`) derived from the machine's Windows Cryptography GUID / hardware seed.
2. **Trial Period**: The client receives a 7-day fully functional trial period from the first launch date.
3. **Activation Request**: The client copies their unique Device Code from the app settings or the expiration prompt and sends it to the author.
4. **Key Generation**: The author enters the client's Device Code into either the GUI Python tool, CLI tool, or PowerShell script. The tool computes the authentic HMAC-SHA256 activation key (`ACT-XXXX-XXXX-XXXX`) signed with the private master secret.
5. **Permanent Unlock**: The client enters the activation key into the application, which verifies the cryptographic signature and grants lifetime access to all lessons and activities.

## Tools:
- [keygen_gui.py](file:///C:/Users/moham/Desktop/Bayan/tools/keygen/keygen_gui.py): Graphical User Interface (Tkinter) key generator. Run with `python keygen_gui.py`. Features an input box for the Device Code, a Generate button, and a 1-click clipboard copy button.
- [keygen.py](file:///C:/Users/moham/Desktop/Bayan/tools/keygen/keygen.py): Command-line key generator. Run with `python keygen.py BYN-XXXX-XXXX-XXXX` or interactively.
- [keygen.ps1](file:///C:/Users/moham/Desktop/Bayan/tools/keygen/keygen.ps1): Native Windows PowerShell script. Run with `.\keygen.ps1 -DeviceCode "BYN-XXXX-XXXX-XXXX"`. Automatically copies the resulting key to the Windows clipboard.
