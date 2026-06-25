#!/bin/sh
# ============================================
# SIMPLE WORKING BACKUP SYSTEM (FIXED)
# ============================================

echo "========================================="
echo "🔄 Simple Backup System"
echo "========================================="

# Setup directories
BACKUP_DIR="/root/backup_test"
mkdir -p "$BACKUP_DIR"

# Find files function
find_files() {
    echo "Looking for files with extensions: $@"
    
    # Clear temp file
    > /tmp/files_to_backup.txt
    
    # Loop through each extension
    for ext in "$@"; do
        # Remove leading dot if present
        ext="${ext#.}"
        echo "Searching for *.$ext files..."
        find /root -type f -name "*.$ext" 2>/dev/null >> /tmp/files_to_backup.txt
    done
    
    # Remove duplicates
    sort -u /tmp/files_to_backup.txt -o /tmp/files_to_backup.txt
    
    # Show what was found
    echo "Files found:"
    cat /tmp/files_to_backup.txt
    echo "Total: $(wc -l < /tmp/files_to_backup.txt) files"
}

# Create test files
create_test_files() {
    echo "Creating test files in /root..."
    cd /root
    [ ! -f test1.txt ] && echo "Test file 1" > test1.txt
    [ ! -f test2.txt ] && echo "Test file 2" > test2.txt
    [ ! -f test3.txt ] && echo "Test file 3" > test3.txt
    [ ! -f program.c ] && echo "#include <stdio.h>" > program.c
    [ ! -f large_test.txt ] && dd if=/dev/zero of=large_test.txt bs=1024 count=150 2>/dev/null
    echo "✅ Test files ready"
}

# Check if files exist
check_files() {
    echo ""
    echo "Files in /root:"
    ls -la /root/*.txt /root/*.c 2>/dev/null || echo "No matching files found"
}

# Main execution
echo ""
echo "Arguments received: $@"

# If no arguments, use default extensions
if [ $# -eq 0 ]; then
    echo "No extensions specified, using defaults: .txt .c"
    set -- .txt .c
fi

# Create test files
create_test_files

# Check what files exist
check_files

# Find files
find_files "$@"

# Create backup if files were found
if [ -s /tmp/files_to_backup.txt ]; then
    echo ""
    echo "📦 Creating backup..."
    
    # Create timestamp
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/backup_${TIMESTAMP}.tar"
    
    # Create the backup
    tar -cf "$BACKUP_FILE" -T /tmp/files_to_backup.txt 2>/dev/null
    
    if [ -f "$BACKUP_FILE" ] && [ -s "$BACKUP_FILE" ]; then
        echo "✅ Backup created successfully!"
        echo "📁 Backup location: $BACKUP_FILE"
        
        # Get file count
        file_count=$(tar -tf "$BACKUP_FILE" | wc -l)
        backup_size=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
        
        echo "📊 Backup stats:"
        echo "   - Files: $file_count"
        echo "   - Size: $backup_size"
        
        echo ""
        echo "📋 Backup contents:"
        tar -tf "$BACKUP_FILE" | head -20
        
        # Show all backup files
        echo ""
        echo "📁 All backups in $BACKUP_DIR:"
        ls -lh "$BACKUP_DIR/"
    else
        echo "❌ Backup creation failed"
    fi
else
    echo "⚠️  No files found to backup"
fi

# Cleanup
rm -f /tmp/files_to_backup.txt

echo ""
echo "========================================="
echo "✅ Done!"
echo "========================================="
