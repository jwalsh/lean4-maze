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

This is promising, as Lake can be used to build and work with Lean4 projects. It also includes a language server feature:
```
$ lake serve
```

This could potentially be used as an alternative to the missing `lean-language-server` binary for IDE integration. Further investigation is needed to resolve these issues for full IDE integration.

## Setup Details

### Makefile

The repository includes a Makefile with the following targets:

- `deps`: Check for required dependencies (Lean4 and Emacs)
- `check-lean`: Check Lean4 installation
- `check-emacs`: Check Emacs installation
- `test-emacs-config`: Test if Emacs can load the project config
- `edit`: Launch Emacs to edit Maze.lean with Lean4 mode
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

## Reporting Issues

If you encounter any issues running this project on FreeBSD, please file an issue with the following information:
- FreeBSD version (`uname -a`)
- Emacs version (`emacs --version`)
- Lean4 version (`pkg info lean4 | grep Version`)
- Description of the problem
- Steps to reproduce