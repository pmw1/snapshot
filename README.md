# Quorus Snapshot Utility

## Overview

`snapshot.sh` is a full-system snapshot script for the Quorus project.  
It creates a detailed, auditable, and restorable record of your project's structure, system environment, files, and configuration.

This utility is critical for **reinstantiating** Quorus after machine rebuilds, migrations, upgrades, or failures.

---

## What It Captures

| Section | Description |
|:---|:---|
| 1 | Project specifications from `reinstantiation/spec/` |
| 2 | Host system environment: hardware, disk, USB devices, installed packages |
| 3 | Project directory tree (5 levels deep) |
| 4 | Full text output of all text-based project files |
| 5 | Ignored files and directories list (with skipped file counts) |
| 6 | Git repository status and last commit (if project under version control) |
| 7 | Important environment variables (`PATH`, `PYTHONPATH`, `USER`, `VIRTUAL_ENV`) |

---

## How It Works

When run, the script:

- **Deletes any previous snapshot** (`snapshot.txt`) to avoid recursion
- **Processes all sections** and writes cleanly into `reinstantiation/snapshot.txt`
- **Ignores binary files, virtual environments, node_modules, old zips, and archives**
- **Prints live console updates** during execution
- **Adds 5 blank lines between sections** for easy reading
- **Captures Git repo info** if present
- **Logs environment variables** necessary for project re-instantiation

---

## Usage

1. Open a terminal.
2. Navigate to your project root directory (where `reinstantiation/` lives).
3. Run:

```bash
bash reinstantiation/snapshot.sh
```

The generated snapshot file will be located at:

```bash
reinstantiation/snapshot.txt
```

---

## Ignore List

The script uses an `ignore_list.txt` file to specify files or directories that should not be processed.

Example `ignore_list.txt`:

```
venv/
node_modules/
used_zips/
nohup.out
*.pyc
__pycache__/
*.zip
*.tar.gz
*.egg-info/
reinstantiation/snapshot.txt
reinstantiation/snapshot.sh
tree.txt
```

Ignored directories are listed in the snapshot summary with **file counts** showing how many files were skipped.

---

## Automation Options

### 📅 Run Daily at 2AM (Cron Job)

You can schedule automatic snapshots with `cron`:

1. Open your crontab editor:

```bash
crontab -e
```

2. Add this line:

```bash
0 2 * * * /bin/bash /full/path/to/reinstantiation/snapshot.sh
```

*(Adjust `/full/path/to/` to your actual project directory.)*

---

### 📂 Git Push Workflow Tip

You can add snapshot generation **before a Git push**:

1. Manually:

```bash
bash reinstantiation/snapshot.sh
git add reinstantiation/snapshot.txt
git commit -m "Update project snapshot"
git push
```

2. Or automate it inside a Git pre-push hook if desired.

---

## Safety Features

- **Deletes old snapshots automatically** to prevent recursive nesting.
- **Ignores output files** during scanning.
- **Only captures text files**, not binaries.
- **If Git is missing**, gracefully skips Git info section.
- **If virtualenv is missing**, gracefully skips venv info.
- **Full timestamps** for both start and finish times.

---

## License

Internal Quorus project tool.  
Unrestricted use by project maintainers.

---