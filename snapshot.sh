#!/bin/bash

# === Project Configuration ===
project_name="QUORUS"
output_file="reinstantiation/snapshot.txt"
ignore_list_file="ignore_list.txt"

start_time=$(date '+%Y-%m-%d %H:%M:%S')

echo "[+] Initializing snapshot for project: $project_name"

# Delete any existing snapshot.txt to prevent recursion
if [ -f "$output_file" ]; then
  echo "[+] Deleting old snapshot file: $output_file"
  rm "$output_file"
fi

> "$output_file"

step=1
total_steps=7

# === Header Section ===
echo "[Step $step/$total_steps] Writing header..."
((step++))

header="THIS IS A REINSTANTIATION FILE INTENDED TO BRING THE GPT UP-TO-DATE WITH THE OBJECTIVE AND CURRENT STATE OF THE PROJECT: $project_name.
*******************************************************************************************
CONTENTS OF THIS FILE:
1. Project Specification files exported from 'reinstantiation/spec/'
2. System environment
3. Python Information (from within the Virtual Environment): Version, PIP, Installed Modules
4. Tree file structure from the project root of the current development environment
5. Full output of all text-based files (separated with headers and footers)
6. Ignored files and directories
7. Git repository info and environment variables snapshot
*******************************************************************************************"

echo "$header" >> "$output_file"

# === Section 1: Project Specification ===
echo "[Step $step/$total_steps] Writing project specification files..."
((step++))

section="******************************************* SECTION 1 **********************************************
This section outputs the project specifications gathered from files located in 'reinstantiation/spec/'.
All specifications are printed in chronological order based on file modification date.
***************************************** BEGIN ***************************************************"
echo "$section" >> "$output_file"

if [ -d "reinstantiation/spec" ]; then
  find reinstantiation/spec/ -type f -printf "%T@ %p
" | sort -n | while read -r line; do
    mod_time=$(echo "$line" | cut -d' ' -f1)
    file_path=$(echo "$line" | cut -d' ' -f2-)
    formatted_time=$(date -d "@$mod_time" "+%Y-%m-%d %H:%M:%S")

    echo "[[[[[ FILE: $file_path | Modified: $formatted_time ]]]]]" >> "$output_file"
    cat "$file_path" >> "$output_file"
    echo >> "$output_file"
    echo "[[[[[ END FILE: $file_path ]]]]]" >> "$output_file"
    echo >> "$output_file"
  done
else
  echo "[[ No project specifications found: 'reinstantiation/spec/' directory does not exist. ]]" >> "$output_file"
fi

echo "***************************************** END SECTION 1 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 2: System Environment ===
echo "[Step $step/$total_steps] Capturing system environment..."
((step++))

section="******************************************* SECTION 2 **********************************************
This section captures the current working environment of the host/development system as of $(date)
***************************************** BEGIN ***************************************************"

section+="

[System Specs]
$(uname -a)

[File System Specs]
$(df -h)

[USB Devices]
$(lsusb)

[Installed Packages]
$(dpkg --get-selections)

[Python Version and Installed Pip Modules]
$(python3 --version)
$(pip list)"

if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
    section+="

[Virtual Environment: Python Version and Installed Pip Modules]
$(python --version)
$(pip list)"
    deactivate
else
    section+="

[Virtual Environment: Python Version and Installed Pip Modules]
(venv not found or not available)"
fi

echo "$section" >> "$output_file"
echo "***************************************** END SECTION 2 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 3: Project Tree Structure ===
echo "[Step $step/$total_steps] Capturing project tree structure..."
((step++))

section="******************************************* SECTION 3 **********************************************
This section prints the tree structure from the project root with 5 levels of recursion as of $(date)
***************************************** BEGIN ***************************************************"

if command -v tree >/dev/null 2>&1; then
  section+="

[Project Tree Structure (depth 5)]
$(tree -L 5)"
else
  section+="

[Project Tree Structure]
(tree command not found — install it with 'sudo apt install tree')"
fi

echo "$section" >> "$output_file"
echo "***************************************** END SECTION 3 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 4: Full File Contents ===
echo "[Step $step/$total_steps] Capturing full file contents..."
((step++))

section="******************************************* SECTION 4 **********************************************
This section outputs the complete contents of all text-based files in the project directory with 5 levels of recursion.
***************************************** BEGIN ***************************************************"
echo "$section" >> "$output_file"

ignore_patterns=()
if [ -f "$ignore_list_file" ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && ignore_patterns+=("$line")
  done < "$ignore_list_file"
fi

should_ignore() {
  for pattern in "${ignore_patterns[@]}"; do
    if [[ "$1" == *"$pattern"* ]]; then
      return 0
    fi
  done
  return 1
}

find . -type f | while read -r file; do
  if should_ignore "$file"; then
    continue
  fi

  file_type=$(file --brief --mime-type "$file")
  
  if echo "$file_type" | grep -q '^text/'; then
    echo "[[[[[ BEGIN FILE: $file ]]]]]" >> "$output_file"
    cat "$file" >> "$output_file"
    echo >> "$output_file"
    echo "[[[[[ END FILE: $file ]]]]]" >> "$output_file"
    echo >> "$output_file"
  else
    echo "[[[[[ BEGIN FILE: $file ]]]]]" >> "$output_file"
    echo "[[ BINARY FILE DETECTED: Content not displayed ]]" >> "$output_file"
    echo "[[[[[ END FILE: $file ]]]]]" >> "$output_file"
    echo >> "$output_file"
  fi
done

echo "***************************************** END SECTION 4 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 5: Ignored Files and Directories ===
echo "[Step $step/$total_steps] Capturing ignored files and directories..."
((step++))

section="******************************************* SECTION 5 **********************************************
This section lists all files and directories that were intentionally omitted based on the ignore list.
***************************************** BEGIN ***************************************************"
echo "$section" >> "$output_file"

if [ ${#ignore_patterns[@]} -eq 0 ]; then
  echo "No ignored files or directories were configured." >> "$output_file"
else
  for pattern in "${ignore_patterns[@]}"; do
    matches=$(find . -path "*$pattern*" 2>/dev/null)
    if [ -n "$matches" ]; then
      for match in $matches; do
        if [ -d "$match" ]; then
          count=$(find "$match" -type f | wc -l)
          echo "[Ignored Directory] $match — $count files omitted" >> "$output_file"
        elif [ -f "$match" ]; then
          echo "[Ignored File] $match" >> "$output_file"
        fi
      done
    else
      echo "[No match found for pattern] $pattern" >> "$output_file"
    fi
  done
fi

echo "***************************************** END SECTION 5 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 6: Git Repository Information ===
echo "[Step $step/$total_steps] Capturing Git repository info (if applicable)..."
((step++))

section="******************************************* SECTION 6 **********************************************
This section captures Git repository status and last commit if the project is version controlled.
***************************************** BEGIN ***************************************************"
echo "$section" >> "$output_file"

if [ -d ".git" ]; then
  echo "[Git Status]" >> "$output_file"
  git status >> "$output_file" 2>/dev/null
  echo >> "$output_file"
  echo "[Last Git Commit]" >> "$output_file"
  git log -1 >> "$output_file" 2>/dev/null
else
  echo "No Git repository detected in project root." >> "$output_file"
fi

echo "***************************************** END SECTION 6 ***************************************************" >> "$output_file"
for i in {1..5}; do echo >> "$output_file"; done

# === Section 7: Key Environment Variables ===
echo "[Step $step/$total_steps] Capturing environment variables..."
((step++))

section="******************************************* SECTION 7 **********************************************
This section captures important environment variables used during project development.
***************************************** BEGIN ***************************************************"
echo "$section" >> "$output_file"

env | grep -E '^(PATH|PYTHONPATH|VIRTUAL_ENV|USER)=' >> "$output_file" || echo "No relevant environment variables found." >> "$output_file"

echo "***************************************** END SECTION 7 ***************************************************" >> "$output_file"

# === Finalization ===
end_time=$(date '+%Y-%m-%d %H:%M:%S')
echo "[✓] Snapshot complete! Started at $start_time, finished at $end_time."