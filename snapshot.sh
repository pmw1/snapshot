#!/bin/bash

# === Snapshot tool to capture project state for LLM handoff ===
# Run from project root; --clear option wipes snapshot artifacts

# Check for --clear option
if [ "$1" = "--clear" ]; then
    if [ ! -f ".project_root" ]; then
        echo "[✖] Error: Not in a project root (no .project_root found)."
        exit 1
    fi
    echo "[+] Clearing snapshot artifacts in $(pwd)..."
    rm -f .project_root ignore_list.txt
    rm -rf reinstantiation
    if [ -f ".project_root" ] || [ -f "ignore_list.txt" ] || [ -d "reinstantiation" ]; then
        echo "[✖] Failed to clear all artifacts. Check permissions."
        exit 1
    fi
    echo "[✔] All snapshot artifacts cleared."
    exit 0
fi

# === Force move to the real project root where .project_root exists ===
if [ -f ".project_root" ]; then
    echo "[+] Project root detected."
else
    echo "[!] No .project_root found. Searching upward..."
    current_dir=$(pwd)
    while [ ! -f "$current_dir/.project_root" ] && [ "$current_dir" != "/" ]; do
        current_dir=$(dirname "$current_dir")
    done
    if [ -f "$current_dir/.project_root" ]; then
        echo "[+] Switching to project root at $current_dir"
        cd "$current_dir" || { echo "[✖] Failed to switch to project root."; exit 1; }
    else
        echo "[!] No .project_root found. Enter project name (e.g., MyProject):"
        read -r project_name
        if [ -z "$project_name" ]; then
            echo "[✖] Error: Project name cannot be empty."
            exit 1
        fi
        # Sanitize project name
        project_name=$(echo "$project_name" | tr -d '\n\r' | sed 's/[^a-zA-Z0-9._-]/-/g')
        echo "$project_name" | tr -d '\r' > ".project_root"
        echo "[+] Created .project_root with project name '$project_name'"
    fi
fi

# === Ensure required project directories exist ===
mkdir -p "reinstantiation" || { echo "[✖] Failed to create directories."; exit 1; }

# === Project Configuration ===
if [ -f ".project_root" ]; then
    project_name=$(cat ".project_root" | tr -d '\r')
    if [ -z "$project_name" ]; then
        echo "[✖] .project_root is empty. Aborting."
        exit 1
    fi
    # Sanitize project_name
    project_name=$(echo "$project_name" | tr -d '\n\r' | sed 's/[^a-zA-Z0-9._-]/-/g')
    echo "[+] Project name loaded: $project_name"
else
    echo "[✖] No .project_root file found after setup. Aborting."
    exit 1
fi

output_file="reinstantiation/snapshot.txt"
ignore_list_file="ignore_list.txt"

# Generate ignore_list.txt on first run with secure defaults
if [ ! -f "$ignore_list_file" ]; then
    echo "[+] Creating $ignore_list_file with secure defaults..."
    echo -e ".env\nkairo_env\n__pycache__\nnode_modules\nsnapshot.txt\n.git\n.obsidian" | tr -d '\r' > "$ignore_list_file"
else
    echo "[+] Using existing $ignore_list_file"
fi

start_time=$(date '+%Y-%m-%d %H:%M:%S')

echo "[+] Initializing snapshot for project: $project_name"

# Delete existing snapshot.txt
if [ -f "$output_file" ]; then
    echo "[+] Deleting old snapshot file: $output_file"
    rm "$output_file" || { echo "[✖] Failed to delete old snapshot."; exit 1; }
fi

> "$output_file" || { echo "[✖] Failed to create snapshot file."; exit 1; }

step=1
total_steps=7

# === Header Section ===
echo "[Step $step/$total_steps] Writing header..."
((step++))

header="THIS IS A REINSTANTIATION FILE INTENDED TO BRING THE LLM UP-TO-DATE WITH THE OBJECTIVE AND CURRENT STATE OF THE PROJECT: $project_name.
===================================================================================
CONTENTS OF THIS FILE:
1. Project Specification files (OBJECTIVE.md, Kairo_Operational_Flow.md)
2. System environment
3. Python Information (from within the Virtual Environment): Version, PIP, Installed Modules
4. Tree file structure from the project root of the current development environment
5. Full output of all text-based files (separated with headers and footers)
6. Ignored files and directories
7. Git repository info and environment variables snapshot
==================================================================================="

echo "$header" | tr -d '\r' >> "$output_file"

# === Section 1: Project Specification ===
echo "[Step $step/$total_steps] Writing project specification files..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 1: PROJECT SPECIFICATIONS"
    echo "==================================================================================="
    echo "This section outputs the project specifications from OBJECTIVE.md and docs/Kairo_Operational_Flow.md."
    echo "------------------------------------ BEGIN ------------------------------------"
    found_files=0
    for file in "OBJECTIVE.md" "docs/Kairo_Operational_Flow.md"; do
        if [ -f "$file" ]; then
            mod_time=$(stat -c %Y "$file" 2>/dev/null || echo "Unknown")
            if [ "$mod_time" != "Unknown" ]; then
                formatted_time=$(date -d "@$mod_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown")
            else
                formatted_time="Unknown"
            fi
            echo "[[[[[ FILE: $file | Modified: $formatted_time ]]]]]"
            cat "$file" | tr -d '\r'
            echo -e "\n[[[[[ END FILE: $file ]]]]]"
            found_files=$((found_files + 1))
        fi
    done
    if [ $found_files -eq 0 ]; then
        echo "[[ No project specifications found: OBJECTIVE.md and docs/Kairo_Operational_Flow.md are missing. ]]"
    fi
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 2: System Environment ===
echo "[Step $step/$total_steps] Capturing system environment..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 2: SYSTEM ENVIRONMENT"
    echo "==================================================================================="
    echo "This section captures the current working environment of the host/development system as of $(date)"
    echo "------------------------------------ BEGIN ------------------------------------"
    echo -e "\n[System Specs]"
    uname -a
    echo -e "\n[File System Specs]"
    df -h
    echo -e "\n[Python Version]"
    python3 --version 2>/dev/null || echo "Python3 not found"
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        echo -e "\n[Virtual Environment]"
        python --version
        echo -e "\n[PIP Modules]"
        pip list
        deactivate
    elif [ -f "kairo_env/bin/activate" ]; then
        source kairo_env/bin/activate
        echo -e "\n[Virtual Environment]"
        python --version
        echo -e "\n[PIP Modules]"
        pip list
        deactivate
    else
        echo -e "\n[Virtual Environment]\n(venv or kairo_env not found or not available)"
    fi
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 3: Project Tree Structure ===
echo "[Step $step/$total_steps] Capturing project tree structure..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 3: PROJECT TREE STRUCTURE"
    echo "==================================================================================="
    echo "This section prints the tree structure from the project root with 5 levels of recursion as of $(date)"
    echo "------------------------------------ BEGIN ------------------------------------"
    if command -v tree >/dev/null 2>&1; then
        echo -e "\n[Project Tree Structure (depth 5)]"
        # Build ignore pattern safely
        ignore_pattern=$(grep -v '^$' "$ignore_list_file" | sed 's/[[\.*^$/]/\\&/g' | tr '\n' '|' | sed 's/|$//')
        if [ -z "$ignore_pattern" ]; then
            tree -L 5
        else
            tree -L 5 -I "$ignore_pattern"
        fi
    else
        echo -e "\n[Project Tree Structure]\n(tree command not found — install it with 'sudo apt install tree')"
    fi
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 4: Full File Contents ===
echo "[Step $step/$total_steps] Capturing full file contents..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 4: FULL FILE CONTENTS"
    echo "==================================================================================="
    echo "This section outputs the complete contents of all text-based files in the project directory with 5 levels of recursion."
    echo "------------------------------------ BEGIN ------------------------------------"
} | tr -d '\r' >> "$output_file"

ignore_patterns=()
while IFS= read -r line; do
    [ -n "$line" ] && ignore_patterns+=("$line")
done < "$ignore_list_file"

find . -maxdepth 5 -type f -not -path "./reinstantiation/snapshot.txt" | while read -r file; do
    for pattern in "${ignore_patterns[@]}"; do
        [[ "$file" == *"$pattern"* ]] && continue 2
    done
    if file --brief --mime-type "$file" | grep -q '^text/'; then
        {
            echo "[[[[[ BEGIN FILE: $file ]]]]]"
            cat "$file" | tr -d '\r'
            echo -e "\n[[[[[ END FILE: $file ]]]]]"
        } | tr -d '\r' >> "$output_file"
    else
        {
            echo "[[[[[ BEGIN FILE: $file ]]]]]"
            echo "[[ BINARY FILE DETECTED: Content not displayed ]]"
            echo "[[[[[ END FILE: $file ]]]]]"
        } | tr -d '\r' >> "$output_file"
    fi
done
{
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 5: Ignored Files and Directories ===
echo "[Step $step/$total_steps] Capturing ignored files and directories..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 5: IGNORED FILES AND DIRECTORIES"
    echo "==================================================================================="
    echo "This section lists all files and directories that were intentionally omitted based on the ignore list."
    echo "------------------------------------ BEGIN ------------------------------------"
    if [ ${#ignore_patterns[@]} -eq 0 ]; then
        echo "No ignored files or directories were configured."
    else
        for pattern in "${ignore_patterns[@]}"; do
            matches=$(find . -maxdepth 5 -path "*$pattern*" 2>/dev/null)
            if [ -n "$matches" ]; then
                echo "$matches" | while read -r match; do
                    if [ -d "$match" ]; then
                        count=$(find "$match" -type f | wc -l)
                        echo "[Ignored Directory] $match — $count files omitted"
                    elif [ -f "$match" ]; then
                        echo "[Ignored File] $match"
                    fi
                done
            else
                echo "[No match found for pattern] $pattern"
            fi
        done
    fi
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 6: Git Repository Information ===
echo "[Step $step/$total_steps] Capturing Git repository info..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 6: GIT REPOSITORY INFORMATION"
    echo "==================================================================================="
    echo "This section captures Git repository status and last commit if the project is version controlled."
    echo "------------------------------------ BEGIN ------------------------------------"
    if [ -d ".git" ]; then
        echo -e "\n[Git Status]"
        git status
        echo -e "\n[Last Git Commit]"
        git log -1
    else
        echo "No Git repository detected in project root."
    fi
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Section 7: Key Environment Variables ===
echo "[Step $step/$total_steps] Capturing environment variables..."
((step++))
{
    echo "==================================================================================="
    echo "SECTION 7: ENVIRONMENT VARIABLES"
    echo "==================================================================================="
    echo "This section captures important environment variables used during project development."
    echo "------------------------------------ BEGIN ------------------------------------"
    env | grep -E '^(PATH|PYTHONPATH|VIRTUAL_ENV|USER)=' || echo "No relevant environment variables found."
    echo "------------------------------------ END ------------------------------------"
    echo -e "\n\n\n\n\n\n"
} | tr -d '\r' >> "$output_file"

# === Finalization ===
end_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "[✓] Snapshot complete! Started at $start_time, finished at $end_time."