# PowerShell-File-Integrity-Checker

# PowerShell File Integrity Checker (F.I.C)

A lightweight security tool built with PowerShell to monitor file system integrity. This project is designed to detect unauthorized changes in sensitive directories by comparing file hashes against a known baseline.

## 🛡️ Purpose

Detecting unauthorized file modifications is crucial for identifying potential malware activity or unauthorized access. This tool automates the process of "fingerprinting" files using the SHA-256 algorithm.

## 🚀 Features

- **Baseline Creation:** Generates a "source of truth" by hashing all files in a target directory.
- **Integrity Monitoring:** Compares current file hashes against the baseline.
- **Change Detection:** Identifies:
  - **Modified Files:** Files that have been tampered with.
  - **New Files:** Unauthorized files added to the directory.
  - **Deleted Files:** Files that have been removed.

## 📋 Prerequisites

- **Windows PowerShell 5.1** or **PowerShell 7+**.
- Execution Policy set to `RemoteSigned`. To do this, run PowerShell as Admin and type:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Force
  ```
