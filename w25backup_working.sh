#!/bin/sh
# ============================================
# LINUX BACKUP AUTOMATION SYSTEM (Working Version)
# ============================================

echo "========================================="
echo "🔄 Linux Backup Automation System"
echo "========================================="
echo "User: $(whoami)"
echo "Directory: $(pwd)"
echo "Arguments: $@"
echo "========================================="

# Configuration
HOME_PATH="/root"
BACKUP_FOLDER="$HOME_PATH/backup"
LOG_FILE="$HOME_PATH/w25log.txt"

# Create directories
mkdir -p "$BACKUP_FOLDER/fullbup"
mkdir -p "$BACKUP_FOLDER/incbup"
mkdir -p "$BACKUP_FOLDER/diffbup"
mkdir -p "$BACKUP_FOLDER/incsizebup"
mkdir -p "$BACKUP_FOLDER/timestamps"

# Counters
fullCounter=1
incCounter=1
diffCounter=1
sizeCounter=1

echo "Backing up extensions: $@"
echo "Log file: $LOG_FILE"
echo ""

# Create test files if they don't exist
cd /root
[ ! -f test1.txt ] && echo "Test 1" > test1.txt
[ ! -f test2.txt ] && echo "Test 2" > test2.txt
[ ! -f test3.txt ] && echo "Test 3" > test3.txt
[ ! -f program.c ] && echo "#include <stdio.h>" > program.c
[ ! -f large_test.txt ] && dd if=/dev/zero of=large_test.txt bs=1024 count=150 2>/dev/null

echo "✅ Test files ready"

# Full backup
do_full_backup() {
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    filename="fullbup-$fullCounter.tar"
    fullpath="$BACKUP_FOLDER/fullbup/$filename"
    
    echo "$current_time - Starting Full Backup: $filename" >> "$LOG_FILE"
    echo "📦 Creating full backup: $filename"
    
    cd /root || return 1
    
    # Find files
    if [ $# -eq 0 ]; then
        find . -type f -readable -print 2>/dev/null > /tmp/filelist.txt
    else
        > /tmp/filelist.txt
        for ext in "$@"; do
            ext="${ext#.}"
            find . -type f -readable -name "*.$ext" -print 2>/dev/null >> /tmp/filelist.txt
        done
    fi
    
    if [ ! -s /tmp/filelist.txt ]; then
        echo "⚠️  No files found"
        echo "$current_time - No files found" >> "$LOG_FILE"
        rm -f /tmp/filelist.txt
        return 0
    fi
    
    tar -cf "$fullpath" -T /tmp/filelist.txt 2>/dev/null
    
    if [ -f "$fullpath" ] && [ -s "$fullpath" ]; then
        count=$(wc -l < /tmp/filelist.txt)
        echo "✅ Created: $filename ($count files)"
        echo "$current_time - ✅ $filename created ($count files)" >> "$LOG_FILE"
        fullCounter=$((fullCounter + 1))
        date +%s > "$BACKUP_FOLDER/timestamps/step1"
    else
        echo "❌ Backup failed"
        echo "$current_time - ❌ Backup failed" >> "$LOG_FILE"
    fi
    
    rm -f /tmp/filelist.txt
}

# Run full backup
do_full_backup "$@"

echo ""
echo "========================================="
echo "✅ Backup completed!"
echo "========================================="
echo "📁 Backups: $BACKUP_FOLDER/fullbup/"
echo "📝 Log: $LOG_FILE"
echo ""

# Show results
ls -la "$BACKUP_FOLDER/fullbup/" 2>/dev/null
echo ""
echo "Backup contents:"
if [ -f "$BACKUP_FOLDER/fullbup/fullbup-1.tar" ]; then
    tar -tf "$BACKUP_FOLDER/fullbup/fullbup-1.tar" | head -10
    file_count=$(tar -tf "$BACKUP_FOLDER/fullbup/fullbup-1.tar" | wc -l)
    echo "Total files in backup: $file_count"
fi
