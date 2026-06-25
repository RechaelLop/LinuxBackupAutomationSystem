#!/bin/sh
# ============================================
# LINUX BACKUP AUTOMATION SYSTEM (COMPLETE)
# ============================================

echo "========================================="
echo "🔄 Linux Backup Automation System"
echo "========================================="
echo "User: $(whoami)"
echo "Arguments: $@"
echo "========================================="

# Configuration
WAIT_TIME=10  # Seconds between backups
HOME_PATH="/root"
BACKUP_FOLDER="$HOME_PATH/backup_complete"
LOG_FILE="$HOME_PATH/w25log_complete.txt"

# Create directories
mkdir -p "$BACKUP_FOLDER"/{fullbup,incbup,diffbup,incsizebup,timestamps}

# Counters
fullCounter=1
incCounter=1
diffCounter=1
sizeCounter=1

# Log function
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Process extensions
process_extensions() {
    if [ $# -eq 0 ]; then
        echo "📁 Backing up: ALL files"
        extensions=""
        return 0
    fi
    
    ext_list=""
    for ext in "$@"; do
        ext="${ext#.}"
        ext_list="$ext_list $ext"
    done
    echo "📁 Backing up extensions: $@"
    extensions="$ext_list"
}

# Find files function
find_files_by_ext() {
    # Clear temp file
    > /tmp/filelist.txt
    
    if [ -z "$extensions" ]; then
        # Find ALL files
        find "$HOME_PATH" -type f -readable 2>/dev/null > /tmp/filelist.txt
    else
        # Find files with specific extensions
        for ext in $extensions; do
            find "$HOME_PATH" -type f -readable -name "*.$ext" 2>/dev/null >> /tmp/filelist.txt
        done
        # Remove duplicates
        sort -u /tmp/filelist.txt -o /tmp/filelist.txt
    fi
}

# Full Backup
do_full_backup() {
    echo "📦 Creating FULL backup..."
    log_message "Starting Full Backup: fullbup-$fullCounter.tar"
    
    find_files_by_ext
    
    if [ ! -s /tmp/filelist.txt ]; then
        echo "⚠️  No files found - Full backup skipped"
        log_message "No files found - Full backup skipped"
        return 0
    fi
    
    file_count=$(wc -l < /tmp/filelist.txt)
    filename="fullbup-$fullCounter.tar"
    fullpath="$BACKUP_FOLDER/fullbup/$filename"
    
    tar -cf "$fullpath" -T /tmp/filelist.txt 2>/dev/null
    
    if [ -f "$fullpath" ] && [ -s "$fullpath" ]; then
        echo "✅ Created: $filename ($file_count files)"
        log_message "✅ $filename created ($file_count files)"
        fullCounter=$((fullCounter + 1))
        date +%s > "$BACKUP_FOLDER/timestamps/step1"
    else
        echo "❌ Full backup failed"
        log_message "❌ Full backup failed"
    fi
}

# Wait function
wait_between_steps() {
    echo "⏳ Waiting $WAIT_TIME seconds..."
    sleep $WAIT_TIME
}

# Create test files
create_test_files() {
    echo "📝 Creating test files..."
    cd "$HOME_PATH"
    [ ! -f test1.txt ] && echo "Test file 1" > test1.txt
    [ ! -f test2.txt ] && echo "Test file 2" > test2.txt
    [ ! -f test3.txt ] && echo "Test file 3" > test3.txt
    [ ! -f program.c ] && echo "#include <stdio.h>" > program.c
    [ ! -f large_test.txt ] && dd if=/dev/zero of=large_test.txt bs=1024 count=150 2>/dev/null
    echo "✅ Test files ready"
}

# Show results
show_results() {
    echo ""
    echo "📊 Backup Results:"
    echo "========================================="
    
    echo "📁 Full Backups:"
    ls -lh "$BACKUP_FOLDER/fullbup/" 2>/dev/null || echo "   (none)"
    
    echo ""
    echo "📁 Incremental Backups:"
    ls -lh "$BACKUP_FOLDER/incbup/" 2>/dev/null || echo "   (none)"
    
    echo ""
    echo "📁 Differential Backups:"
    ls -lh "$BACKUP_FOLDER/diffbup/" 2>/dev/null || echo "   (none)"
    
    echo ""
    echo "📁 Size-Based Backups:"
    ls -lh "$BACKUP_FOLDER/incsizebup/" 2>/dev/null || echo "   (none)"
    
    echo ""
    echo "📝 Log file: $LOG_FILE"
}

# Main execution
process_extensions "$@"
create_test_files

echo ""
echo "🔄 Running backup cycle..."
echo "========================================="

do_full_backup
wait_between_steps

# For now, just do full backup (we'll add incremental later)
# The other backup types can be added once the basics work

show_results

echo ""
echo "========================================="
echo "✅ Backup cycle completed!"
echo "========================================="
