# Linux Backup Automation System

A comprehensive Bash-based backup system for Linux that performs multiple backup types (full, incremental, differential, size-based) at regular intervals.


---



## 📋 Features

- **Full Backup** - Complete backup of all specified file types
- **Incremental Backup** - Backs up only files changed since the previous backup
- **Differential Backup** - Backs up all files changed since the last full backup
- **Size-Based Backup** - Backs up only large files (>100KB) that have changed
- **Continuous Operation** - Runs as a background process
- **Detailed Logging** - Maintains comprehensive logs of all operations
- **Smart Resumption** - Detects existing backups and continues numbering


---


## 🗂️ Backup Types

The system implements four different backup strategies to balance storage efficiency and recovery speed:

| Backup Type | Description | Storage | Recovery |
|-------------|-------------|---------|----------|
| **Full** | Complete backup of all specified files | High | Fast |
| **Incremental (Step 2)** | Files changed since the last full backup | Low | Slow |
| **Incremental (Step 3)** | Files changed since the previous incremental backup | Low | Slow |
| **Differential** | All files changed since the last full backup | Medium | Medium |
| **Size-Based** | Large files (>100KB) changed since differential backup | Very Low | Fast |


---


## 🚀 Installation

### Prerequisites
- **Linux operating system** (or WSL on Windows / Docker container)
- **Bash shell** (version 4.0 or higher)
- **`tar` utility** (typically pre-installed)

### Setup

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/LinuxBackupAutomationSystem.git
cd LinuxBackupAutomationSystem

# Make the script executable
chmod +x w25backup.sh

# (Optional) Create a symbolic link for global access
sudo ln -s $(pwd)/w25backup.sh /usr/local/bin/backup


---


## Author

- **Rechael Lopes**
- **Github Link - https://github.com/RechaelLop/LinuxBackupAutomationSystem**