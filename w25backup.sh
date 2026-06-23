#!/bin/bash

# ============================================
# LINUX BACKUP AUTOMATION SYSTEM
# Author: Rechael Lopes
# Description: Automatically backs up files
# ============================================

# The script will have 5 backup types:
# 1. Full backup - backs up ALL files
# 2. Incremental 1 - backs up files changed since full backup
# 3. Incremental 2 - backs up files changed since last incremental
# 4. Differential - backs up all files changed since full backup
# 5. Size-based - backs up large files (>100KB) changed recently

# ============================================
# VARIABLES (Like containers for information)
# ============================================

# Constants - These NEVER change
WAIT_TIME_BETWEEN_STEPS=120  # 2 minutes in seconds

# These variables will be set later
MY_USERNAME=""               # Your username
HOME_PATH=""                 # Your home directory
BACKUP_FOLDER=""             # Where backups go
LOG_FILE_PATH=""             # Log file location

# Counters - These track how many backups we've made
fullBackupCounter=1          # Starts at 1
incrementalCounter=1
diffBackupCounter=1
sizeBackupCounter=1

# File extensions to backup
extensionsToBackup=""        # Will be filled from command line
descriptionOfExtensions=""   # Human-readable description

# Folder paths for different backup types
fullBACKUP_dir=""            # Full backups folder
incrBACKUP_dir=""            # Incremental backups folder
diffrentialBACKUP_dir=""     # Differential backups folder
incSIZE_backup_dir=""        # Size-based backups folder
TIMESTAMP_DIR=""             # Timestamps folder

# Timestamp files (store when each backup was made)
timeStamp_step1=""           # After full backup
timeStamp_step2=""           # After first incremental
timeStamp_step3=""           # After second incremental
timeStamp_step4=""           # After differential
timeStamp_step5=""           # After size-based


# ============================================
# INITIALIZATION FUNCTION
# Sets up all paths and creates folders
# ============================================

init_paths_and_folders() {
    # Get your username
    MY_USERNAME=$(whoami)
    
    # Set home directory path (fix for root in WSL)
    if [ "$MY_USERNAME" = "root" ]; then
        HOME_PATH="/root"
    else
        HOME_PATH="/home/$MY_USERNAME"
    fi
    
    # Set log file path
    LOG_FILE_PATH="$HOME_PATH/w25log.txt"
    
    # Create log file if it doesn't exist
    if [ ! -f "$LOG_FILE_PATH" ]; then
        touch "$LOG_FILE_PATH"
        echo "Log file created at $(date)" >> "$LOG_FILE_PATH"
    fi
    
    # Set backup directory paths
    BACKUP_FOLDER="$HOME_PATH/backup"
    fullBACKUP_dir="${BACKUP_FOLDER}/fullbup"
    incrBACKUP_dir="${BACKUP_FOLDER}/incbup"
    diffrentialBACKUP_dir="$BACKUP_FOLDER/diffbup"
    incSIZE_backup_dir="$BACKUP_FOLDER/incsizebup"
    TIMESTAMP_DIR="$BACKUP_FOLDER/timestamps"
    
    # Set timestamp file paths
    timeStamp_step1="$TIMESTAMP_DIR/step1_time"
    timeStamp_step2="$TIMESTAMP_DIR/step2_time"
    timeStamp_step3="$TIMESTAMP_DIR/step3_time"
    timeStamp_step4="$TIMESTAMP_DIR/step4_time"
    timeStamp_step5="$TIMESTAMP_DIR/step5_time"
    
    # Call the function to create folders
    create_backup_folders
}


# ============================================
# FOLDER CREATION FUNCTION
# Creates all required directories
# ============================================

create_backup_folders() {
    # List of folders to create
    # This is an array - a list of items
    folders_to_create=(
        "$BACKUP_FOLDER"
        "$fullBACKUP_dir"
        "$incrBACKUP_dir"
        "$diffrentialBACKUP_dir"
        "$incSIZE_backup_dir"
        "$TIMESTAMP_DIR"
    )
    
    # Loop through each folder
    # for...in...do...done is a loop
    for folder in "${folders_to_create[@]}"; do
        # Check if folder already exists
        if [ ! -d "$folder" ]; then
            # Create the folder (-p creates parent folders too)
            mkdir -p "$folder"
            echo "Created directory: $folder" >> "$LOG_FILE_PATH"
        fi
    done
}

# ============================================
# COMMAND-LINE PROCESSING FUNCTION
# Handles what you type when running the script
# ============================================

process_command_arguments() {
    # Reset variables
    extensionsToBackup=""
    descriptionOfExtensions=""
    
    # Check if you typed any arguments
    # $# means "number of arguments"
    if [ $# -eq 0 ]; then
        # No arguments = backup EVERYTHING
        extensionsToBackup="*"
        descriptionOfExtensions="all files"
        echo "No extensions specified. Will backup ALL files." >> "$LOG_FILE_PATH"
    else
        # Process each argument
        # This loop goes through each file extension you typed
        arg_idx=1
        while [ $arg_idx -le $# ]; do
            # Get the current argument
            # ${!arg_idx} gets the argument at position arg_idx
            current_ext="${!arg_idx}"
            
            # Check if extension starts with a dot
            # If not, add one
            if [[ ! "$current_ext" =~ ^\..+$ ]]; then
                echo "Warning: '$current_ext' doesn't start with '.'. Adding '.' automatically." >> "$LOG_FILE_PATH"
                current_ext=".$current_ext"
            fi
            
            # Add to extensions string
            extensionsToBackup="$extensionsToBackup *${current_ext}"
            
            # Build a human-readable description
            if [ -z "$descriptionOfExtensions" ]; then
                descriptionOfExtensions="${current_ext}"
            else
                descriptionOfExtensions="${descriptionOfExtensions}, ${current_ext}"
            fi
            
            # Move to next argument
            arg_idx=$((arg_idx + 1))
        done
        echo "Will backup extensions: $descriptionOfExtensions" >> "$LOG_FILE_PATH"
    fi
}


# ============================================
# COUNTER MANAGEMENT FUNCTION
# Checks existing backups to continue numbering
# ============================================

check_previous_backups() {
    echo "Checking for existing backups..." >> "$LOG_FILE_PATH"
    
    # Check full backups
    if [ -d "$fullBACKUP_dir" ] && [ "$(ls -A $fullBACKUP_dir 2>/dev/null)" ]; then
        latest_backup=$(ls -1 "$fullBACKUP_dir" | grep "fullbup-" | sort -V | tail -n 1)
        if [ -n "$latest_backup" ]; then
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            if [ -n "$latest_num" ]; then
                fullBackupCounter=$((latest_num + 1))
                echo "Found existing full backups. Starting from counter: $fullBackupCounter" >> "$LOG_FILE_PATH"
            fi
        fi
    fi
    
    # Check incremental backups
    if [ -d "$incrBACKUP_dir" ] && [ "$(ls -A $incrBACKUP_dir 2>/dev/null)" ]; then
        latest_backup=$(ls -1 "$incrBACKUP_dir" | grep "incbup-" | sort -V | tail -n 1)
        if [ -n "$latest_backup" ]; then
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            if [ -n "$latest_num" ]; then
                incrementalCounter=$((latest_num + 1))
                echo "Found existing incremental backups. Starting from counter: $incrementalCounter" >> "$LOG_FILE_PATH"
            fi
        fi
    fi
    
    # Check differential backups
    if [ -d "$diffrentialBACKUP_dir" ] && [ "$(ls -A $diffrentialBACKUP_dir 2>/dev/null)" ]; then
        latest_backup=$(ls -1 "$diffrentialBACKUP_dir" | grep "diffbup-" | sort -V | tail -n 1)
        if [ -n "$latest_backup" ]; then
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            if [ -n "$latest_num" ]; then
                diffBackupCounter=$((latest_num + 1))
                echo "Found existing differential backups. Starting from counter: $diffBackupCounter" >> "$LOG_FILE_PATH"
            fi
        fi
    fi
    
    # Check size-based backups
    if [ -d "$incSIZE_backup_dir" ] && [ "$(ls -A $incSIZE_backup_dir 2>/dev/null)" ]; then
        latest_backup=$(ls -1 "$incSIZE_backup_dir" | grep "incsizebup-" | sort -V | tail -n 1)
        if [ -n "$latest_backup" ]; then
            latest_num=$(echo "$latest_backup" | sed 's/[^0-9]*//g')
            if [ -n "$latest_num" ]; then
                sizeBackupCounter=$((latest_num + 1))
                echo "Found existing size-based backups. Starting from counter: $sizeBackupCounter" >> "$LOG_FILE_PATH"
            fi
        fi
    fi
}


# ============================================
# FULL BACKUP FUNCTION
# Creates a complete backup of all files
# ============================================

do_full_backup() {
    # Get current date/time for logging
    current_time=$(date "+%a %d %b %Y %I:%M:%S %p %Z")
    
    # Create filename (e.g., fullbup-1.tar)
    FB_filename="fullbup-$fullBackupCounter.tar"
    FB_full_path="$fullBACKUP_dir/$FB_filename"
    
    echo "$current_time Starting Full Backup: $FB_filename" >> "$LOG_FILE_PATH"
    
    # Move to home directory
    # cd changes directory
    # || means "if the previous command fails"
    cd "$HOME_PATH" || return 1
    
    # Create a temporary file to store the list of files
    # mktemp creates a unique temporary file
    TEMP_FILE=$(mktemp)
    
    # Find files to backup
    # find searches for files
    # -type f means regular files only
    # -readable means we can read them
    if [ "$extensionsToBackup" = "*" ]; then
        # Find ALL files
        find . -type f -readable -print 2>/dev/null > "$TEMP_FILE"
    else
        # Find files with specific extensions
        clean_extensions="${extensionsToBackup# }"  # Remove leading space
        IFS=' ' read -ra extension_array <<< "$clean_extensions"  # Split into array
        for ext in "${extension_array[@]}"; do
            # -name "$ext" matches files with that extension
            find . -type f -readable -name "$ext" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    # Check if we found any files
    # -s checks if file is not empty
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No files found - Full backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"  # Clean up temp file
        return 0
    fi
    
    # Create the tar archive
    # tar -cf creates an archive
    # -T uses a list of files from the temp file
    tar -cf "$FB_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    # Check if backup was created successfully
    if [ -f "$FB_full_path" ] && [ -s "$FB_full_path" ]; then
        # Log success
        # wc -l counts lines in the file
        file_count=$(wc -l < "$TEMP_FILE")
        echo "$current_time $FB_filename was created" >> "$LOG_FILE_PATH"
        echo "  - Contains $file_count files" >> "$LOG_FILE_PATH"
        
        # Increment counter for next time
        fullBackupCounter=$((fullBackupCounter + 1))
        
        # Store timestamp (current time in seconds since 1970)
        date +%s > "$timeStamp_step1"
    else
        echo "$current_time Error - Full backup failed" >> "$LOG_FILE_PATH"
        # Remove failed backup file if it exists
        [ -f "$FB_full_path" ] && rm "$FB_full_path"
    fi
    
    # Clean up temp file
    rm "$TEMP_FILE"
}


# ============================================
# WAIT FUNCTION
# Pauses between backup steps
# ============================================

wait_between_steps() {
    local wait_time=${1:-$WAIT_TIME_BETWEEN_STEPS}
    echo "Waiting $wait_time seconds before next backup..." >> "$LOG_FILE_PATH"
    sleep "$wait_time"
}

# ============================================
# INCREMENTAL BACKUP (Step 2)
# Backs up files changed since full backup
# ============================================

do_incremental_backup_step2() {
    current_time=$(date "+%a %d %b %Y %I:%M:%S %p %Z")
    
    # Check if timestamp from step 1 exists
    if [ ! -f "$timeStamp_step1" ]; then
        echo "$current_time Error - No timestamp from full backup. Skipping incremental backup." >> "$LOG_FILE_PATH"
        return 1
    fi
    
    # Create backup filename
    INC_filename="incbup-$incrementalCounter.tar"
    INC_full_path="$incrBACKUP_dir/$INC_filename"
    
    echo "$current_time Starting Incremental Backup: $INC_filename" >> "$LOG_FILE_PATH"
    
    cd "$HOME_PATH" || return 1
    
    TEMP_FILE=$(mktemp)
    
    # Find files modified since full backup
    if [ "$extensionsToBackup" = "*" ]; then
        find . -type f -readable -newer "$timeStamp_step1" -print 2>/dev/null > "$TEMP_FILE"
    else
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        for ext in "${extension_array[@]}"; do
            find . -type f -readable -name "$ext" -newer "$timeStamp_step1" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No changes - Incremental backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    tar -cf "$INC_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    if [ -f "$INC_full_path" ] && [ -s "$INC_full_path" ]; then
        file_count=$(wc -l < "$TEMP_FILE")
        echo "$current_time $INC_filename was created" >> "$LOG_FILE_PATH"
        echo "  - Contains $file_count files" >> "$LOG_FILE_PATH"
        incrementalCounter=$((incrementalCounter + 1))
        date +%s > "$timeStamp_step2"
    else
        echo "$current_time Error - Incremental backup failed" >> "$LOG_FILE_PATH"
        [ -f "$INC_full_path" ] && rm "$INC_full_path"
    fi
    
    rm "$TEMP_FILE"
}

# ============================================
# INCREMENTAL BACKUP (Step 3)
# Backs up files changed since previous incremental
# ============================================

do_incremental_backup_step3() {
    current_time=$(date "+%a %d %b %Y %I:%M:%S %p %Z")
    
    if [ ! -f "$timeStamp_step2" ]; then
        echo "$current_time Error - No timestamp from step 2. Skipping incremental backup." >> "$LOG_FILE_PATH"
        return 1
    fi
    
    INC_filename="incbup-$incrementalCounter.tar"
    INC_full_path="$incrBACKUP_dir/$INC_filename"
    
    echo "$current_time Starting Incremental Backup (Step 3): $INC_filename" >> "$LOG_FILE_PATH"
    
    cd "$HOME_PATH" || return 1
    
    TEMP_FILE=$(mktemp)
    
    if [ "$extensionsToBackup" = "*" ]; then
        find . -type f -readable -newer "$timeStamp_step2" -print 2>/dev/null > "$TEMP_FILE"
    else
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        for ext in "${extension_array[@]}"; do
            find . -type f -readable -name "$ext" -newer "$timeStamp_step2" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No changes - Incremental backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    tar -cf "$INC_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    if [ -f "$INC_full_path" ] && [ -s "$INC_full_path" ]; then
        file_count=$(wc -l < "$TEMP_FILE")
        echo "$current_time $INC_filename was created" >> "$LOG_FILE_PATH"
        echo "  - Contains $file_count files" >> "$LOG_FILE_PATH"
        incrementalCounter=$((incrementalCounter + 1))
        date +%s > "$timeStamp_step3"
    else
        echo "$current_time Error - Incremental backup failed" >> "$LOG_FILE_PATH"
        [ -f "$INC_full_path" ] && rm "$INC_full_path"
    fi
    
    rm "$TEMP_FILE"
}

# ============================================
# DIFFERENTIAL BACKUP
# Backs up all files changed since full backup
# ============================================

do_differential_backup() {
    current_time=$(date "+%a %d %b %Y %I:%M:%S %p %Z")
    
    if [ ! -f "$timeStamp_step1" ]; then
        echo "$current_time Error - No timestamp from full backup. Skipping differential backup." >> "$LOG_FILE_PATH"
        return 1
    fi
    
    DIFF_filename="diffbup-$diffBackupCounter.tar"
    DIFF_full_path="$diffrentialBACKUP_dir/$DIFF_filename"
    
    echo "$current_time Starting Differential Backup: $DIFF_filename" >> "$LOG_FILE_PATH"
    
    cd "$HOME_PATH" || return 1
    
    TEMP_FILE=$(mktemp)
    
    if [ "$extensionsToBackup" = "*" ]; then
        find . -type f -readable -newer "$timeStamp_step1" -print 2>/dev/null > "$TEMP_FILE"
    else
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        for ext in "${extension_array[@]}"; do
            find . -type f -readable -name "$ext" -newer "$timeStamp_step1" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No changes - Differential backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    tar -cf "$DIFF_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    if [ -f "$DIFF_full_path" ] && [ -s "$DIFF_full_path" ]; then
        file_count=$(wc -l < "$TEMP_FILE")
        echo "$current_time $DIFF_filename was created" >> "$LOG_FILE_PATH"
        echo "  - Contains $file_count files" >> "$LOG_FILE_PATH"
        diffBackupCounter=$((diffBackupCounter + 1))
        date +%s > "$timeStamp_step4"
    else
        echo "$current_time Error - Differential backup failed" >> "$LOG_FILE_PATH"
        [ -f "$DIFF_full_path" ] && rm "$DIFF_full_path"
    fi
    
    rm "$TEMP_FILE"
}

# ============================================
# SIZE-BASED BACKUP
# Backs up large files (>100KB) changed recently
# ============================================

do_incremental_size_backup() {
    current_time=$(date "+%a %d %b %Y %I:%M:%S %p %Z")
    
    if [ ! -f "$timeStamp_step4" ]; then
        echo "$current_time Error - No timestamp from differential backup. Skipping size-based backup." >> "$LOG_FILE_PATH"
        return 1
    fi
    
    SIZE_filename="incsizebup-$sizeBackupCounter.tar"
    SIZE_full_path="$incSIZE_backup_dir/$SIZE_filename"
    
    echo "$current_time Starting Size-Based Backup: $SIZE_filename" >> "$LOG_FILE_PATH"
    
    cd "$HOME_PATH" || return 1
    
    TEMP_FILE=$(mktemp)
    
    if [ "$extensionsToBackup" = "*" ]; then
        find . -type f -readable -size +100k -newer "$timeStamp_step4" -print 2>/dev/null > "$TEMP_FILE"
    else
        clean_extensions="${extensionsToBackup# }"
        IFS=' ' read -ra extension_array <<< "$clean_extensions"
        for ext in "${extension_array[@]}"; do
            find . -type f -readable -size +100k -name "$ext" -newer "$timeStamp_step4" -print 2>/dev/null >> "$TEMP_FILE"
        done
    fi
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo "$current_time No large files changed - Size-based backup was not created" >> "$LOG_FILE_PATH"
        rm "$TEMP_FILE"
        return 0
    fi
    
    tar -cf "$SIZE_full_path" -T "$TEMP_FILE" 2>/dev/null
    
    if [ -f "$SIZE_full_path" ] && [ -s "$SIZE_full_path" ]; then
        file_count=$(wc -l < "$TEMP_FILE")
        echo "$current_time $SIZE_filename was created" >> "$LOG_FILE_PATH"
        echo "  - Contains $file_count large files (>100KB)" >> "$LOG_FILE_PATH"
        sizeBackupCounter=$((sizeBackupCounter + 1))
        date +%s > "$timeStamp_step5"
    else
        echo "$current_time Error - Size-based backup failed" >> "$LOG_FILE_PATH"
        [ -f "$SIZE_full_path" ] && rm "$SIZE_full_path"
    fi
    
    rm "$TEMP_FILE"
}

# ============================================
# MAIN EXECUTION
# ============================================

run_backup_cycle() {
    echo "=========================================" >> "$LOG_FILE_PATH"
    echo "Starting new backup cycle at $(date)" >> "$LOG_FILE_PATH"
    echo "=========================================" >> "$LOG_FILE_PATH"
    
    # Step 1: Full backup
    do_full_backup
    wait_between_steps
    
    # Step 2: Incremental backup after FULL
    do_incremental_backup_step2
    wait_between_steps
    
    # Step 3: Incremental backup after STEP 2
    do_incremental_backup_step3
    wait_between_steps
    
    # Step 4: Differential backup
    do_differential_backup
    wait_between_steps
    
    # Step 5: Size-based backup
    do_incremental_size_backup
    
    echo "Backup cycle completed at $(date)" >> "$LOG_FILE_PATH"
    echo "" >> "$LOG_FILE_PATH"
}

run_continuous_backup() {
    # Initialize everything
    init_paths_and_folders
    check_previous_backups
    
    echo "Starting continuous backup system..." >> "$LOG_FILE_PATH"
    echo "Backing up: $descriptionOfExtensions" >> "$LOG_FILE_PATH"
    echo "Log file: $LOG_FILE_PATH" >> "$LOG_FILE_PATH"
    echo "Press Ctrl+C to stop" >> "$LOG_FILE_PATH"
    
    # Run forever (while true is an infinite loop)
    while true; do
        run_backup_cycle
    done
}


# ============================================
# PROGRAM STARTS HERE
# ============================================

# Process what you typed on the command line
process_command_arguments "$@"

# Start the backup system
run_continuous_backup