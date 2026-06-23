# Linux Backup Automation System

A comprehensive Bash-based backup system for Linux that performs multiple backup types (full, incremental, differential, size-based) at regular intervals.

## 📋 Features

- **Full Backup** - Complete backup of all specified file types
- **Incremental Backup** - Backs up only files changed since the previous backup
- **Differential Backup** - Backs up all files changed since the last full backup
- **Size-Based Backup** - Backs up only large files (>100KB) that have changed
- **Continuous Operation** - Runs as a background process
- **Detailed Logging** - Maintains comprehensive logs of all operations
- **Smart Resumption** - Detects existing backups and continues numbering