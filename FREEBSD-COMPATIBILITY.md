# FreeBSD Compatibility for Lean4-Maze

This document provides information about compatibility and setup instructions for running the Lean4 Maze project on FreeBSD systems.

## Testing Status (Work in Progress)

This is currently a work in progress. Initial testing shows that Lean4 and Emacs can be installed on FreeBSD 14.3, and the necessary configuration has been set up to integrate them.

### Current Testing Approach
- Using package management (`pkg`) to install Lean4 and Emacs
- Local clone of lean4-mode repository for Emacs integration
- Makefile targets for verifying installation and launching Emacs
- Tmux sessions for terminal-based testing and output capture

#### TTY/Tmux Testing Process
```bash
# Create a detached tmux session running Emacs with our configuration
tmux new-session -d -s lean_test 'emacs -nw --no-init-file --load ./.emacs-project.el Maze.lean'

# Allow Emacs to initialize
sleep 2

# Capture the current screen state
tmux capture-pane -t lean_test -p > /tmp/emacs_screen.txt

# Send keystrokes to respond to prompts (e.g., 'y' to accept local variables)
tmux send-keys -t lean_test 'y'

# Wait for processing
sleep 2

# Capture updated screen
tmux capture-pane -t lean_test -p > /tmp/emacs_screen_after.txt

# Clean up when done
tmux kill-session -t lean_test
```

This approach allows for semi-automated testing of the Emacs and Lean4 integration by capturing terminal output at various stages of the process.

### Next Steps
- Complete interactive testing in Emacs with Lean4 mode
- Develop better terminal screen capture methods (potentially using tools like `script` or `ttyrec`)
- Create a more robust testing script with error handling and timeout mechanisms
- Document any FreeBSD-specific issues or workarounds

## Tested Environment

| Component        | Version                 | Notes                                       |
|------------------|-------------------------|---------------------------------------------|
| Operating System | FreeBSD 14.3-RELEASE    | amd64 architecture                          |
| Emacs            | GNU Emacs 30.1          | Available in FreeBSD ports/packages         |
| Lean4            | 4.12.0                  | Available in FreeBSD ports/packages         |
| lean4-mode       | Git (latest)            | Included as local clone in this repository  |

## Setup Instructions

1. Install required packages:
   ```
   pkg install lean4 emacs
   ```

2. Clone this repository:
   ```
   git clone https://github.com/jwalsh/lean4-maze.git
   cd lean4-maze
   ```

3. The repository includes:
   - Project-specific Emacs configuration (`.emacs-project.el`)
   - Directory-local variables (`.dir-locals.el`) that load the project config
   - A local copy of `lean4-mode` for Emacs integration
   - A Makefile with targets for dependency checking and launching Emacs

4. Check dependencies and start editing:
   ```
   make deps     # Check if all dependencies are properly installed
   make edit     # Launch Emacs with Lean4 mode to edit Maze.lean
   ```

## Known Issues

- The `lean` command doesn't return version information directly and shows an error: `error: failed to locate application` despite being installed correctly
- The `lean-language-server` binary is not available, which may affect IDE integration
- Lake (Lean4 build tool) is included with the lean4 package and appears to work correctly

### Lean4 Binary and Language Server Investigation

The Lean4 binary is installed at `/usr/local/bin/lean` and has correct permissions:
```
$ which lean && ls -la $(which lean)
/usr/local/bin/lean
-rwxr-xr-x  1 root wheel 4888 Apr 13 20:33 /usr/local/bin/lean
```

When trying to run the Lean executable, it fails with:
```
$ lean --verbose
error: failed to locate application
```

Library dependencies look correct:
```
$ ldd /usr/local/bin/lean
/usr/local/bin/lean:
	libc++.so.1 => /lib/libc++.so.1
	libcxxrt.so.1 => /lib/libcxxrt.so.1
	libInit_shared.so => /usr/local/bin/../lib/lean/libInit_shared.so
	libleanshared_1.so => /usr/local/bin/../lib/lean/libleanshared_1.so
	libleanshared.so => /usr/local/bin/../lib/lean/libleanshared.so
	libgmp.so.10 => /usr/local/bin/../lib/libgmp.so.10
	libuv.so.1 => /usr/local/bin/../lib/libuv.so.1
	libm.so.5 => /lib/libm.so.5
	libthr.so.3 => /lib/libthr.so.3
	libc.so.7 => /lib/libc.so.7
	libgcc_s.so.1 => /lib/libgcc_s.so.1
```

The language server components are part of the package but the executable is missing:
```
$ which lean-language-server
lean-language-server not found
```

However, Lake (the Lean4 build tool) works correctly:
```
$ lake --help
Lake version 5.0.0-src (Lean version 4.12.0)
...
```

#### Language Server Resolution

Looking at the `lean4-mode.el` source code reveals how the language server is determined:

```elisp
(defun lean4--server-cmd ()
  "Return Lean server command.
If found lake version at least 3.1.0, then return '/path/to/lake serve',
otherwise return '/path/to/lean --server'."
  (condition-case nil
      (if (string-version-lessp (car (process-lines (lean4-get-executable "lake") "--version")) "3.1.0")
          `(,(lean4-get-executable lean4-executable-name) "--server")
        `(,(lean4-get-executable "lake") "serve"))
    (error `(,(lean4-get-executable lean4-executable-name) "--server"))))
```

This shows that:
1. For Lake versions 3.1.0 and above, Lean4 mode uses `lake serve` as the language server
2. For earlier versions, it uses `lean --server`

Since Lake works properly on our FreeBSD installation (version 5.0.0) but the Lean executable doesn't, we've configured our `.emacs-project.el` to explicitly use `lake serve` as the language server command:

```elisp
(setq lsp-lean4-server-command '("lake" "serve"))
```

This should allow Emacs to connect to the language server for Lean4 projects, even though the standard `lean` executable isn't functioning properly on FreeBSD.

## Setup Details

### Lean Language Server Protocol (LSP) Integration

Lean4 implements the Language Server Protocol (LSP) to provide IDE features such as code completion, diagnostics, and goal information. On FreeBSD, we've identified a few nuances with the LSP implementation:

1. The standard Lean LSP server is typically accessed via:
   - `lean --server` (for older versions)
   - `lake serve` (for Lake 3.1.0 and newer)

2. In our FreeBSD setup, we're using `lake serve` since:
   - The `lean` executable has issues on FreeBSD
   - Lake 5.0.0 is installed and working correctly

#### LSP Implementation Details

The Lean4 LSP server provides several capabilities:
- File change notifications and incremental parsing
- Diagnostics (errors, warnings, infos)
- Hover information
- Go-to-definition
- Find references
- Completion suggestions
- Goal state information for theorem proving

The language server works by maintaining an in-memory representation of Lean modules and processing changes incrementally, which is essential for the interactive nature of Lean theorem proving.

### Python LeanClient Integration

We've included a Python integration with LeanClient to demonstrate programmatic interaction with the Lean Language Server:

1. Install the leanclient package:
   ```bash
   uv init
   uv venv
   uv pip install leanclient
   ```

2. Use the provided `maze.py` script to interact with the Lean server:
   ```bash
   # Either manually:
   source .venv/bin/activate
   python maze.py
   
   # Or using the Makefile target:
   make test-python
   ```

This allows you to:
- Query goal states programmatically
- Make document changes
- Get diagnostic information
- Interact with Lean through Python scripts

The FreeBSD setup has been tested with Python 3.11.11, which works well with leanclient.

### MCP (Model Context Protocol) Integration

The [lean-lsp-mcp](https://github.com/oOo0oOo/lean-lsp-mcp) project provides a Model Context Protocol (MCP) server for integrating Lean theorem prover with AI assistants. This can be particularly helpful for interacting with the Lean4 Maze project.

To use it with Claude Code:

1. Install uv (Python package manager):
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

2. Make sure your Lean project builds:
   ```bash
   lake build
   ```

3. Configure Claude Code to use the MCP server:
   ```bash
   claude mcp add lean-lsp uvx lean-lsp-mcp -e LEAN_PROJECT_PATH=$PWD
   ```

For other AI assistants or IDEs like VSCode, see the [lean-lsp-mcp README](https://github.com/oOo0oOo/lean-lsp-mcp) for specific setup instructions.

The MCP server provides several useful tools for working with Lean projects:
- File interaction (viewing contents, diagnostic messages, proof goals)
- External search tools for finding theorems and definitions
- Project-level tools like building projects

This integration is particularly valuable on FreeBSD where the standard Lean4 executable and language server have some issues.

### Makefile

The repository includes a Makefile with the following targets:

- `deps`: Check for required dependencies (Lean4 and Emacs)
- `check-lean`: Check Lean4 installation
- `check-emacs`: Check Emacs installation
- `test-emacs-config`: Test if Emacs can load the project config
- `edit`: Launch Emacs to edit Maze.lean with Lean4 mode
- `test-tmux`: Run automated testing using tmux (generates a screenshot)
- `test-python`: Run Python LeanClient test to interact with Lean LSP
- `help`: Show all available targets

### Emacs Integration

The repository includes a project-specific Emacs configuration that:

1. Sets up package repositories (MELPA, GNU ELPA)
2. Ensures necessary packages are available (lsp-mode, company)
3. Configures Lean4 mode to work with the local Lean4 installation
4. Provides code completion and other IDE-like features

#### Language Server Configuration

Since the standard `lean-language-server` binary is not available on FreeBSD, the configuration has been updated to use Lake's serve command as an alternative:

```elisp
;; Use Lake's serve command as the language server
(setq lsp-lean4-server-command '("lake" "serve"))
```

This should allow Emacs to connect to a language server for Lean4 projects. When opening Maze.lean in Emacs, you should see syntax highlighting, and with the language server running, code completion and other IDE features should be available.

#### Useful Keybindings

The following LSP-mode keybindings are available when working with Lean files in Emacs:

| Keybinding | Description |
|------------|-------------|
| `C-c C-h` | Display hover information at point |
| `C-c C-p` | Navigate to previous location in file |
| `C-c C-n` | Navigate to next location in file |
| `C-c .` | Find definition |
| `C-c ,` | Find references |
| `C-c C-r` | Rename symbol |
| `C-c C-a` | Execute code action |
| `C-c C-d` | Show documentation for symbol at point |
| `C-c C-l` | Show diagnostics (errors and warnings) |
| `M-RET` | Show code actions |

For a complete list of keybindings, see the [LSP Mode keybindings documentation](https://emacs-lsp.github.io/lsp-mode/page/keybindings/).

Lean4-mode specific keybindings:
| Keybinding | Description |
|------------|-------------|
| `C-c C-g` | Show goal at point |
| `C-c C-i` | Show info at point |
| `C-c C-t` | Show type at point |
| `C-c SPC` | Fill placeholder |
| `C-c C-SPC` | Show all goals |

For more details, see the [lean4-mode README](https://github.com/leanprover-community/lean4-mode).

## Additional Resources

### Official Documentation

- [Lean4 Documentation](https://lean-lang.org/documentation/) - Official documentation for Lean4
- [Lean4 Manual](https://lean-lang.org/lean4/doc/) - Comprehensive manual for Lean4
- [Theorem Proving in Lean4](https://lean-lang.org/theorem_proving_in_lean4/) - Introduction to theorem proving
- [Functional Programming in Lean](https://lean-lang.org/functional_programming_in_lean/) - Introduction to functional programming
- [Lean Language Server Protocol (LSP)](https://github.com/leanprover/lean4/blob/master/src/Lean/Server/README.md) - Documentation for Lean4's LSP implementation
- [LeanClient Documentation](https://leanclient.readthedocs.io/en/latest/) - Python library for interacting with Lean4's LSP

### Community Resources

- [Lean4 GitHub Repository](https://github.com/leanprover/lean4) - Source code for Lean4
- [Lean4 Mode GitHub Repository](https://github.com/leanprover-community/lean4-mode) - Source code for Lean4 Emacs mode
- [Lean Zulip Chat](https://leanprover.zulipchat.com/) - Community chat for Lean users
- [Lean Stack Exchange](https://leanprover.github.io/lean4/doc/how_to_get_help.html) - Q&A for Lean users

### FreeBSD Specific Resources

- [FreeBSD Ports Collection](https://www.freebsd.org/ports/) - Information about FreeBSD ports
- [FreeBSD Handbook: Packages and Ports](https://docs.freebsd.org/en/books/handbook/ports/) - Guide to installing software on FreeBSD
- [FreeBSD Forums](https://forums.freebsd.org/) - Community forums for FreeBSD users

### Troubleshooting References

- [LSP Mode Documentation](https://emacs-lsp.github.io/lsp-mode/) - Documentation for LSP mode in Emacs
- [Lean4 Debugging Guide](https://lean-lang.org/lean4/doc/dev/debugging.html) - Guide for debugging Lean4 issues
- [FreeBSD Debugging Applications](https://docs.freebsd.org/en/books/developers-handbook/debugging/) - Guide for debugging applications on FreeBSD
- [Lean Lake Documentation](https://github.com/leanprover/lake) - Documentation for the Lake build tool

### Common Troubleshooting Steps

#### LSP Server Connection Issues

If you encounter issues with the language server connection:

1. Check if Lake is working correctly:
   ```bash
   lake --version
   ```

2. Try running the language server manually:
   ```bash
   lake serve
   ```

3. Enable LSP debugging in Emacs:
   ```elisp
   (setq lsp-log-io t)
   ```

4. Check the LSP logs:
   ```
   M-x lsp-workspace-show-log
   ```

#### Missing Definitions or Hover Information

If code navigation or hover information isn't working:

1. Make sure the project builds correctly:
   ```bash
   lake build
   ```

2. Try restarting the LSP server:
   ```
   M-x lsp-workspace-restart
   ```

3. Ensure file dependencies are refreshed:
   ```
   C-c C-d (lean4-refresh-file-dependencies)
   ```

#### Syntax Highlighting Issues

If syntax highlighting isn't working correctly:

1. Ensure lean4-mode is properly loaded:
   ```
   M-x describe-mode
   ```

2. Try enabling semantic tokens explicitly:
   ```elisp
   (setq-local lsp-semantic-tokens-enable t)
   ```

3. Restart Emacs with minimal configuration:
   ```bash
   emacs -Q --load ./.emacs-project.el Maze.lean
   ```

## Reporting Issues

If you encounter any issues running this project on FreeBSD, please file an issue with the following information:
- FreeBSD version (`uname -a`)
- Emacs version (`emacs --version`)
- Lean4 version (`pkg info lean4 | grep Version`)
- Description of the problem
- Steps to reproduce