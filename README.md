```markdown
# Snapshot Tool

The `snapshot` tool generates a `snapshot.txt` file that captures the current state of a software project, designed to facilitate handoff to a Large Language Model (LLM) for analysis, debugging, or planning. It collects project specifications, system environment details, file structure, file contents, ignored files, Git status, and environment variables into a single, well-organized text file.

## Purpose

The `snapshot` tool is ideal for developers who need to:
- Share project context with an LLM for code review, debugging, or feature planning.
- Document a project’s state at a specific point in time.
- Track changes efficiently with minimal output for iterative updates.
- Customize which sections of the snapshot are included based on project needs.

## Installation

### Prerequisites
- **Bash**: Available on Linux/macOS (or WSL on Windows).
- **tree**: Required for file structure output. Install with:
  ```bash
  sudo apt install tree  # Debian/Ubuntu
  brew install tree      # macOS
  ```
- **Git**: Optional for change tracking and repository info.
- **Python**: Optional for virtual environment details.

### Setup
1. **Clone or Download**:
   - Clone the repository (e.g., `https://github.com/pmw1/snapshot.git`):
     ```bash
     git clone https://github.com/pmw1/snapshot.git
     cd snapshot
     ```
   - Or download `snapshot.sh` and `install_snapshot.sh` manually.

2. **Set Permissions**:
   ```bash
   chmod +x snapshot.sh install_snapshot.sh
   ```

3. **Install System-Wide**:
   - Run the installer to place `snapshot` in `/usr/local/bin`:
     ```bash
     ./install_snapshot.sh
     ```
   - This requires `sudo` for system-wide access. If prompted, confirm overwriting existing `snapshot` binaries.

4. **Verify Installation**:
   ```bash
   snapshot --sections-list
   ```
   - If this lists sections, the tool is ready.

## Usage

Run `snapshot` from your project directory (where your project’s files reside):
```bash
snapshot [flags]
```

The output is saved to `reinstantiation/snapshot.txt` in the project directory.

### Flags
- **`--clear`**:
  - Removes all snapshot-related artifacts (`.project_root`, `ignore_list.txt`, `.snapshot_last_run`, `reinstantiation/`).
  - Example:
    ```bash
    snapshot --clear
    ```
  - Use to reset before a fresh snapshot.

- **`--update`**:
  - Generates a minimal snapshot with only the file tree (section 3) and changed files (section 4) since the last run.
  - Detects changes via Git (`git diff`) or file modification times (`.snapshot_last_run`).
  - Example:
    ```bash
    snapshot --update
    ```

- **`--disable-sections <sections>`**:
  - Skips specified sections (comma-separated, e.g., `2,5`).
  - Useful for excluding irrelevant data (e.g., system environment).
  - Example:
    ```bash
    snapshot --disable-sections 2,5
    ```

- **`--sections-list`**:
  - Lists all sections with their titles and exits without generating a snapshot.
  - Example:
    ```bash
    snapshot --sections-list
    ```
    Output:
    ```
    Available sections in snapshot.txt:
    SECTION 1: PROJECT SPECIFICATIONS
    SECTION 2: SYSTEM ENVIRONMENT
    SECTION 3: PROJECT TREE STRUCTURE
    SECTION 4: FULL FILE CONTENTS
    SECTION 5: IGNORED FILES AND DIRECTORIES
    SECTION 6: GIT REPOSITORY INFORMATION
    SECTION 7: ENVIRONMENT VARIABLES
    ```

### Combining Flags
- Flags like `--disable-sections` and `--update` can be combined, but `--update` overrides to include only sections 3 and 4.
- Example:
  ```bash
  snapshot --update --disable-sections 3
  ```
  - This outputs only section 4 (changed files), as `--update` limits to sections 3 and 4, and `--disable-sections 3` skips the tree.

## Sections

The `snapshot.txt` file is divided into sections, each providing specific project details:

1. **PROJECT SPECIFICATIONS**:
   - Includes contents of `OBJECTIVE.md` and `docs/Kairo_Operational_Flow.md` (if present).
   - Lists project goals and operational flow.

2. **SYSTEM ENVIRONMENT**:
   - Captures OS details (`uname -a`), memory usage (`free -h`), disk usage (`df -h`), Python version, and virtual environment packages (if `venv` or similar exists).

3. **PROJECT TREE STRUCTURE**:
   - Displays directory structure up to 5 levels deep using `tree`.
   - Excludes files/folders listed in `ignore_list.txt`.

4. **FULL FILE CONTENTS**:
   - Outputs full text of all text-based files (up to 5 levels deep).
   - In `--update` mode, only changed files since the last snapshot.
   - Binary files are marked as `[BINARY FILE DETECTED]`.

5. **IGNORED FILES AND DIRECTORIES**:
   - Lists files/folders excluded based on `ignore_list.txt` (e.g., `.env`, `__pycache__`).

6. **GIT REPOSITORY INFORMATION**:
   - Shows Git status and last commit (if in a Git repo).
   - Helps track version control state.

7. **ENVIRONMENT VARIABLES**:
   - Lists key variables (`PATH`, `PYTHONPATH`, `VIRTUAL_ENV`, `USER`).

## Configuration

- **Project Root**:
  - The tool creates a `.project_root` file with the project name if none exists.
  - It searches upward for `.project_root` to ensure it runs in the correct directory.

- **Ignore List**:
  - A default `ignore_list.txt` is generated with:
    ```
    .env
    kairo_env
    __pycache__
    node_modules
    snapshot.txt
    .git
    .obsidian
    .snapshot_last_run
    ```
  - Edit `ignore_list.txt` to customize exclusions.

## Examples

1. **Full Snapshot**:
   ```bash
   cd /path/to/project
   snapshot
   ```
   - Generates `reinstantiation/snapshot.txt` with all sections.

2. **Minimal Update**:
   ```bash
   snapshot --update
   ```
   - Outputs only the file tree and changed files.

3. **Exclude System and Git Info**:
   ```bash
   snapshot --disable-sections 2,6
   ```
   - Skips system environment and Git sections.

4. **View Sections**:
   ```bash
   snapshot --sections-list
   ```
   - Lists all sections for reference.

## Troubleshooting

- **No `tree` Command**:
  - Section 3 will note if `tree` is missing. Install it (e.g., `sudo apt install tree`).

- **Permission Issues**:
  - Ensure write access to the project directory for `reinstantiation/` and artifact files.
  - Run `install_snapshot.sh` with `sudo` if installing to `/usr/local/bin`.

- **Git Not Found**:
  - Section 6 will indicate if no Git repo exists. Initialize one with `git init` if needed.

- **Missing Sections**:
  - Check `--disable-sections` or `--update` flags if sections are unexpectedly absent.

## Contributing

- **Repository**: `https://github.com/pmw1/snapshot.git`
- **Issues**: Report bugs or suggest features via GitHub Issues.
- **Pull Requests**: Submit improvements to the repository.

## Notes

- The tool is designed for flexibility, allowing customization via flags and `ignore_list.txt`.
- Use `--clear` to reset artifacts before major changes.
- For large projects, consider using `--update` to reduce output size.
- The `.snapshot_last_run` file tracks the last run timestamp for `--update` mode.

---
*Last updated: April 2025*
```