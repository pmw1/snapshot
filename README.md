# Snapshot

A Bash tool to capture a project's state in a `snapshot.txt` file, enabling seamless handoff to Large Language Models (LLMs) for continuing development. It generates a detailed reinstantiation file with project specs, environment, file structure, code, and Git status, designed to work with any project containing a `.project_root` file.

## Purpose

The `snapshot` tool creates a structured output file (`reinstantiation/snapshot.txt`) that LLMs can parse to pick up where previous development left off. It’s ideal for projects where multiple LLMs or developers need context without manual setup.

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/pmw1/snapshot.git
   cd snapshot
   ```

2. **Run the Installer**:
   ```bash
   ./install_snapshot.sh
   ```
   - Installs `snapshot` globally to `$HOME/.local/bin`.
   - Adds `$HOME/.local/bin` to your `PATH` (in `.bashrc`, `.zshrc`, or Fish config).
   - Source your shell config if prompted:
     ```bash
     source ~/.bashrc  # or ~/.zshrc, ~/.config/fish/config.fish
     ```

3. **Verify Installation**:
   ```bash
   command -v snapshot
   ```
   If not found, ensure `$HOME/.local/bin` is in your `PATH`.

## Usage

1. **Navigate to a Project**:
   ```bash
   cd /path/to/your/project
   ```

2. **Run Snapshot**:
   ```bash
   snapshot
   ```
   - If `.project_root` exists, it uses the project name from it.
   - If not, it searches upward or prompts for a project name (e.g., `MyProject`), creating `.project_root`.
   - Generates `reinstantiation/snapshot.txt` in the project root.

3. **Optional: Ignore Files**:
   Create an `ignore_list.txt` in the project root to skip files/directories:
   ```bash
   echo -e "node_modules\n__pycache__\nsnapshot.txt\nvenv" > ignore_list.txt
   ```

4. **Share with LLM**:
   - Open `reinstantiation/snapshot.txt` and share its contents (or sections) with an LLM.
   - The file includes:
     1. Project specifications (`reinstantiation/spec/`).
     2. System environment (OS, Python version).
     3. Python virtual environment details (if `venv` exists).
     4. File structure (up to 5 levels deep).
     5. Text file contents (excluding ignored files).
     6. Ignored files/directories.
     7. Git status and environment variables.

## Requirements

- **Bash**: Available on Linux/macOS.
- **find, sed, cut**: Standard Unix tools.
- **tree** (optional): For file structure (install with `sudo apt install tree` on Debian/Ubuntu).
- **Python 3** (optional): For virtual environment details.
- **Git** (optional): For repository status.

## Example

In a project directory:
```bash
cd ~/myproject
snapshot
# Prompts for project name if .project_root is missing
# Enter: myproject
```
Output: `~/myproject/reinstantiation/snapshot.txt` with project state.

Share `snapshot.txt` with an LLM to continue development.

## Notes

- **Global Install**: Run `snapshot` from any directory; it operates relative to the current project root.
- **macOS Compatibility**: Uses `stat` for file timestamps on macOS.
- **Large Projects**: Adjust `find` depth (`-maxdepth 5`) in `snapshot.sh` or use `ignore_list.txt` for performance.
- **Existing snapshot Command**: If `snapshot` is taken, edit `SCRIPT_NAME` in `install_snapshot.sh`.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Issues and PRs are welcome at [github.com/pmw1/snapshot](https://github.com/pmw1/snapshot).