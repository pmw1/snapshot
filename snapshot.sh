```bash
#!/bin/bash

# Snapshot tool for project state; supports --clear, --update, --disable-sections, --sections-list

# Define section titles
declare -A sections=(
    [1]="PROJECT SPECIFICATIONS"
    [2]="SYSTEM ENVIRONMENT"
    [3]="PROJECT TREE STRUCTURE"
    [4]="FULL FILE CONTENTS"
    [5]="IGNORED FILES AND DIRECTORIES"
    [6]="GIT REPOSITORY INFORMATION"
    [7]="ENVIRONMENT VARIABLES"
)

# Parse flags
while [ $# -gt 0 ]; do
    case "$1" in
        --clear)
            CLEAR_MODE=1
            shift
            ;;
        --update)
            UPDATE_MODE=1
            shift
            ;;
        --disable-sections)
            DISABLED_SECTIONS="$2"
            shift 2
            ;;
        --sections-list)
            SECTIONS_LIST=1
            shift
            ;;
        *)
            echo "[✖] Unknown flag: $1"
            exit 1
            ;;
    esac
done

# Handle --sections-list
if [ -n "$SECTIONS_LIST" ]; then
    echo "Available sections in snapshot.txt:"
    for i in "${!sections[@]}"; do
        echo "SECTION $i: ${sections[$i]}"
    done
    exit 0
fi

# Check for --clear
if [ -n "$CLEAR_MODE" ]; then
    [ ! -f ".project_root" ] && { echo "[✖] Not in project root."; exit 1; }
    echo "[+] Clearing artifacts..."
    rm -f .project_root ignore_list.txt .snapshot_last_run
    rm -rf reinstantiation
    [ -f ".project_root" ] || [ -f "ignore_list.txt" ] || [ -d "reinstantiation" ] && { echo "[✖] Failed to clear."; exit 1; }
    echo "[✔] Artifacts cleared."
    exit 0
fi

# Move to project root
if [ -f ".project_root" ]; then
    echo "[+] Project root detected."
else
    echo "[!] No .project_root. Searching..."
    current_dir=$(pwd)
    while [ ! -f "$current_dir/.project_root" ] && [ "$current_dir" != "/" ]; do
        current_dir=$(dirname "$current_dir")
    done
    if [ -f "$current_dir/.project_root" ]; then
        echo "[+] Switching to $current_dir"
        cd "$current_dir" || { echo "[✖] Failed to switch."; exit 1; }
    else
        echo "[!] No .project_root. Enter project name:"
        read -r project_name
        [ -z "$project_name" ] && { echo "[✖] Name empty."; exit 1; }
        project_name=$(echo "$project_name" | tr -d '\n\r' | sed 's/[^a-zA-Z0-9._-]/-/g')
        echo "$project_name" | tr -d '\r' > ".project_root"
        echo "[+] Created .project_root: $project_name"
    fi
fi

# Project config
project_name=$(cat ".project_root" | tr -d '\r')
[ -z "$project_name" ] && { echo "[✖] .project_root empty."; exit 1; }
project_name=$(echo "$project_name" | tr -d '\n\r' | sed 's/[^a-zA-Z0-9._-]/-/g')
output_file="reinstantiation/snapshot.txt"
ignore_list_file="ignore_list.txt"
mkdir -p "reinstantiation" || { echo "[✖] Failed to create reinstantiation."; exit 1; }

# Generate ignore_list.txt
if [ ! -f "$ignore_list_file" ]; then
    echo "[+] Creating $ignore_list_file..."
    echo -e ".env\nkairo_env\n__pycache__\nnode_modules\nsnapshot.txt\n.git\n.obsidian\n.snapshot_last_run" | tr -d '\r' > "$ignore_list_file"
else
    echo "[+] Using $ignore_list_file"
fi

# Parse disabled sections
declare -A disabled
IFS=',' read -ra sections <<< "$DISABLED_SECTIONS"
for section in "${sections[@]}"; do
    disabled[$section]=1
done

start_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "[+] Initializing snapshot for: $project_name"

# Delete old snapshot.txt
[ -f "$output_file" ] && { echo "[+] Deleting old snapshot..."; rm "$output_file" || { echo "[✖] Failed to delete."; exit 1; }; }
> "$output_file" || { echo "[✖] Failed to create snapshot."; exit 1; }

# Header
if [ -n "$UPDATE_MODE" ]; then
    header="THIS IS A REINSTANTIATION UPDATE FOR PROJECT: $project_name.
===================================================================================
CONTENTS:
3. Tree file structure
4. Changed files since last snapshot
==================================================================================="
else
    header="THIS IS A REINSTANTIATION FILE FOR PROJECT: $project_name.
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
fi
echo "$header" | tr -d '\r' >> "$output_file"

step=1
total_steps=7

# Section 1: Project Specification
if [ -z "$UPDATE_MODE" ] && [ -z "${disabled[1]}" ]; then
    echo "[Step $step/$total_steps] Writing specs..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 1: PROJECT SPECIFICATIONS"
        echo "==================================================================================="
        echo "This section outputs specs from OBJECTIVE.md and docs/Kairo_Operational_Flow.md."
        echo "------------------------------------ BEGIN ------------------------------------"
        found_files=0
        for file in "OBJECTIVE.md" "docs/Kairo_Operational_Flow.md"; do
            if [ -f "$file" ]; then
                mod_time=$(stat -c %Y "$file" 2>/dev/null || echo "Unknown")
                [ "$mod_time" != "Unknown" ] && formatted_time=$(date -d "@$mod_time" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "Unknown") || formatted_time="Unknown"
                echo "[[[[[ FILE: $file | Modified: $formatted_time ]]]]]"
                cat "$file" | tr -d '\r'
                echo -e "\n[[[[[ END FILE: $file ]]]]]"
                found_files=$((found_files + 1))
            fi
        done
        [ $found_files -eq 0 ] && echo "[[ No specs found: OBJECTIVE.md and docs/Kairo_Operational_Flow.md missing. ]]"
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 2: System Environment
if [ -z "$UPDATE_MODE" ] && [ -z "${disabled[2]}" ]; then
    echo "[Step $step/$total_steps] Capturing env..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 2: SYSTEM ENVIRONMENT"
        echo "==================================================================================="
        echo "This section captures the env as of $(date)"
        echo "------------------------------------ BEGIN ------------------------------------"
        echo -e "\n[System Specs]"
        uname -a
        echo -e "\n[Memory Info]"
        free -h
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
            echo -e "\n[Virtual Environment]\n(venv or kairo_env not found)"
        fi
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 3: Project Tree Structure
if [ -z "${disabled[3]}" ]; then
    echo "[Step $step/$total_steps] Capturing tree..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 3: PROJECT TREE STRUCTURE"
        echo "==================================================================================="
        echo "This section prints the tree with 5 levels as of $(date)"
        echo "------------------------------------ BEGIN ------------------------------------"
        if command -v tree >/dev/null 2>&1; then
            echo -e "\n[Project Tree Structure (depth 5)]"
            ignore_pattern=$(grep -v '^$' "$ignore_list_file" | sed 's/[[\.*^$/]/\\&/g' | tr '\n' '|' | sed 's/|$//')
            [ -z "$ignore_pattern" ] && tree -L 5 || tree -L 5 -I "$ignore_pattern"
        else
            echo -e "\n[Project Tree Structure]\n(tree not found — install with 'sudo apt install tree')"
        fi
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 4: File Contents
if [ -z "${disabled[4]}" ]; then
    echo "[Step $step/$total_steps] Capturing files..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 4: $( [ -n "$UPDATE_MODE" ] && echo "CHANGED FILE CONTENTS" || echo "FULL FILE CONTENTS" )"
        echo "==================================================================================="
        echo "This section outputs $( [ -n "$UPDATE_MODE" ] && echo "changed files since last snapshot" || echo "all text-based files" ) with 5 levels."
        echo "------------------------------------ BEGIN ------------------------------------"
    } | tr -d '\r' >> "$output_file"

    ignore_patterns=()
    while IFS= read -r line; do
        [ -n "$line" ] && ignore_patterns+=("$line")
    done < "$ignore_list_file"

    if [ -n "$UPDATE_MODE" ]; then
        changed_files=()
        if [ -d ".git" ] && command -v git >/dev/null 2>&1; then
            changed_files=($(git diff --name-only HEAD^ HEAD 2>/dev/null))
        elif [ -f ".snapshot_last_run" ]; then
            last_run=$(cat ".snapshot_last_run")
            while IFS= read -r file; do
                [ -f "$file" ] && [ $(stat -c %Y "$file") -gt "$last_run" ] && changed_files+=("$file")
            done < <(find . -maxdepth 5 -type f -not -path "./reinstantiation/snapshot.txt")
        fi

        for file in "${changed_files[@]}"; do
            skip=0
            for pattern in "${ignore_patterns[@]}"; do
                [[ "$file" == *"$pattern"* ]] && skip=1 && break
            done
            [ $skip -eq 1 ] && continue
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
    else
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
    fi
    {
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 5: Ignored Files
if [ -z "$UPDATE_MODE" ] && [ -z "${disabled[5]}" ]; then
    echo "[Step $step/$total_steps] Capturing ignored..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 5: IGNORED FILES AND DIRECTORIES"
        echo "==================================================================================="
        echo "This section lists omitted files/directories."
        echo "------------------------------------ BEGIN ------------------------------------"
        [ ${#ignore_patterns[@]} -eq 0 ] && echo "No ignored files configured." || {
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
        }
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 6: Git Repository Info
if [ -z "$UPDATE_MODE" ] && [ -z "${disabled[6]}" ]; then
    echo "[Step $step/$total_steps] Capturing Git..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 6: GIT REPOSITORY INFORMATION"
        echo "==================================================================================="
        echo "This section captures Git status and last commit."
        echo "------------------------------------ BEGIN ------------------------------------"
        if [ -d ".git" ]; then
            echo -e "\n[Git Status]"
            git status
            echo -e "\n[Last Git Commit]"
            git log -1
        else
            echo "No Git repository detected."
        fi
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Section 7: Environment Variables
if [ -z "$UPDATE_MODE" ] && [ -z "${disabled[7]}" ]; then
    echo "[Step $step/$total_steps] Capturing env vars..."
    ((step++))
    {
        echo "==================================================================================="
        echo "SECTION 7: ENVIRONMENT VARIABLES"
        echo "==================================================================================="
        echo "This section captures key env variables."
        echo "------------------------------------ BEGIN ------------------------------------"
        env | grep -E '^(PATH|PYTHONPATH|VIRTUAL_ENV|USER)=' || echo "No relevant env variables found."
        echo "------------------------------------ END ------------------------------------"
        echo -e "\n\n\n\n\n\n"
    } | tr -d '\r' >> "$output_file"
fi

# Save last run timestamp
date +%s > ".snapshot_last_run"

# Finalization
end_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "[✓] Snapshot complete! Started at $start_time, finished at $end_time."
```