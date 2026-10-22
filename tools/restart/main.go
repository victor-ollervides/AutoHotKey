package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
)

const (
	colorReset  = "\033[0m"
	colorGreen  = "\033[32m"
	colorYellow = "\033[33m"
	colorRed    = "\033[31m"
	colorCyan   = "\033[36m"
	colorBold   = "\033[1m"
)

func main() {
	printHeader()

	// Get repository root (executable is in tools/restart)
	exePath, err := os.Executable()
	if err != nil {
		printError("Failed to get executable path: " + err.Error())
		os.Exit(1)
	}

	repoRoot := filepath.Join(filepath.Dir(exePath), "..", "..")
	repoRoot, _ = filepath.Abs(repoRoot)

	// Define tool paths
	terminator := filepath.Join(repoRoot, "tools", "process-killer", "go", "terminator-go.exe")
	launcher := filepath.Join(repoRoot, "tools", "startup-launcher", "cpp", "startup-launcher-cpp.exe")

	// Verify tools exist
	if !fileExists(terminator) {
		printError(fmt.Sprintf("Terminator not found: %s", terminator))
		pause()
		os.Exit(1)
	}

	if !fileExists(launcher) {
		printError(fmt.Sprintf("Launcher not found: %s", launcher))
		pause()
		os.Exit(1)
	}

	// Track overall success
	overallSuccess := true

	// Step 1: Kill all AutoHotkey processes
	printStep(1, "Terminating AutoHotkey processes")
	fmt.Println()

	startTime := time.Now()
	if err := runCommand(terminator); err != nil {
		printWarning(fmt.Sprintf("Terminator exited with error: %v", err))
		overallSuccess = false
	}
	fmt.Println()

	// Brief pause to ensure processes are fully terminated
	time.Sleep(500 * time.Millisecond)

	// Step 2: Launch startup scripts
	fmt.Println()
	printStep(2, "Launching startup scripts")
	fmt.Println()

	if err := runCommand(launcher); err != nil {
		printError(fmt.Sprintf("Launcher failed: %v", err))
		overallSuccess = false
	}

	elapsed := time.Since(startTime)

	// Print summary
	fmt.Println()
	printSeparator()
	if overallSuccess {
		printSuccess("✓ Restart completed successfully!")
	} else {
		printWarning("⚠ Restart completed with warnings")
	}
	fmt.Printf("Total execution time: %dms\n", elapsed.Milliseconds())
	printSeparator()
	fmt.Println()

	pause()
}

func runCommand(cmdPath string) error {
	cmd := exec.Command(cmdPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func printHeader() {
	fmt.Println()
	printSeparator()
	fmt.Printf("%s%s  AutoHotkey Restart Tool%s\n", colorBold, colorCyan, colorReset)
	printSeparator()
	fmt.Println()
}

func printSeparator() {
	fmt.Println("═══════════════════════════════════════════════════════════════════════════")
}

func printStep(step int, message string) {
	fmt.Printf("%s[STEP %d/2]%s %s\n", colorCyan, step, colorReset, message)
}

func printSuccess(message string) {
	fmt.Printf("%s%s%s\n", colorGreen, message, colorReset)
}

func printWarning(message string) {
	fmt.Printf("%s%s%s\n", colorYellow, message, colorReset)
}

func printError(message string) {
	fmt.Printf("%s[ERROR]%s %s\n", colorRed, colorReset, message)
}

func pause() {
	fmt.Print("Press Enter to exit...")
	fmt.Scanln()
}
