.PHONY: deps help check-lean check-emacs test-emacs-config edit test-tmux

help:
	@echo "Available targets:"
	@echo "  deps              - Check for required dependencies (Lean4 and Emacs)"
	@echo "  check-lean        - Check Lean4 installation"
	@echo "  check-emacs       - Check Emacs installation"
	@echo "  test-emacs-config - Test if Emacs can load the project config"
	@echo "  edit              - Launch Emacs to edit Maze.lean with Lean4 mode"
	@echo "  test-tmux         - Run automated testing using tmux"
	@echo "  help              - Show this help message"

deps: check-lean check-emacs test-emacs-config
	@echo "All dependencies checked."

check-lean:
	@echo "Checking Lean4 installation..."
	@which lean || (echo "Lean4 not found. Install with: pkg install lean4" && exit 1)
	@echo "Lean4 binary found at: $$(which lean)"
	@pkg info lean4 | grep Version
	@echo "Lean4 is properly installed."
	@echo "Checking for Lake (Lean4 build tool)..."
	@which lake || echo "Lake not found. It may need to be installed separately."

check-emacs:
	@echo "Checking Emacs installation..."
	@which emacs || (echo "Emacs not found. Install with: pkg install emacs" && exit 1)
	@emacs --version | head -n 1
	@echo "Emacs is properly installed."
	@echo ""
	@echo "To use Emacs with Lean4 for this project:"
	@echo "1. Open Emacs with: emacs Maze.lean"
	@echo "2. The .dir-locals.el file will load the project configuration"
	@echo "3. If prompted about directory variables being unsafe, select 'y' to allow"
	@echo ""
	@echo "If lean4-mode is not installed, you can install it manually with:"
	@echo "M-x package-refresh-contents RET"
	@echo "M-x package-install RET lean4-mode RET"

test-emacs-config:
	@echo "Testing Emacs configuration loading..."
	@emacs --batch --no-init-file --load ./.emacs-project.el --eval "(message \"Successfully loaded project configuration.\")" 2>&1 || echo "Failed to load Emacs configuration."

edit:
	@echo "Launching Emacs with Lean4 mode..."
	@emacs -nw --no-init-file --load ./.emacs-project.el Maze.lean

test-tmux:
	@echo "Running automated test using tmux..."
	@tmux new-session -d -s lean_test 'emacs -nw --no-init-file --load ./.emacs-project.el Maze.lean'
	@sleep 2
	@echo "Capturing initial screen state..."
	@tmux capture-pane -t lean_test -p > /tmp/emacs_screen.txt
	@echo "Sending keystrokes to accept local variables..."
	@tmux send-keys -t lean_test 'y'
	@sleep 2
	@echo "Sending keystrokes to accept LSP server restart..."
	@tmux send-keys -t lean_test 'y'
	@sleep 5
	@echo "Capturing updated screen state..."
	@tmux capture-pane -t lean_test -p > /tmp/emacs_screen_after.txt
	@echo "Saving screenshot to screenshot.txt..."
	@tmux capture-pane -t lean_test -p > screenshot.txt
	@echo "Cleaning up tmux session..."
	@tmux kill-session -t lean_test
	@echo "Test complete. Screen captures saved to /tmp/emacs_screen.txt, /tmp/emacs_screen_after.txt, and screenshot.txt"
	@echo "Examine these files to verify Emacs and Lean4 mode are working correctly."