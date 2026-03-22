package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"time"
)

type StartupLauncher struct {
	scriptsPath string
	logFile     *os.File
}

func NewStartupLauncher(scriptsPath string) (*StartupLauncher, error) {
	logFile, err := os.OpenFile("startup-launcher.log", os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, err
	}

	return &StartupLauncher{
		scriptsPath: scriptsPath,
		logFile:     logFile,
	}, nil
}

func (sl *StartupLauncher) Close() {
	if sl.logFile != nil {
		sl.logFile.Close()
	}
}

func (sl *StartupLauncher) logMessage(message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logEntry := fmt.Sprintf("[%s] %s\n", timestamp, message)

	if sl.logFile != nil {
		sl.logFile.WriteString(logEntry)
	}
	fmt.Print(logEntry)
}

func (sl *StartupLauncher) findAutoHotkeyExecutable() string {
	ahkPaths := []string{
		"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey.exe",
		"C:\\Program Files\\AutoHotkey\\AutoHotkeyU64.exe",
		"C:\\Program Files\\AutoHotkey\\AutoHotkey.exe",
	}

	for _, path := range ahkPaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return ""
}

func (sl *StartupLauncher) launchScript(scriptPath, ahkPath string) error {
	cmd := exec.Command(ahkPath, scriptPath)

	// Hide the window
	cmd.SysProcAttr = &syscall.SysProcAttr{
		HideWindow: true,
	}

	err := cmd.Start()
	if err != nil {
		return err
	}

	// Don't wait for the process to finish
	go func() {
		cmd.Wait()
	}()

	return nil
}

func (sl *StartupLauncher) Run() error {
	sl.logMessage("startup-launcher.go | Starting elevated AutoHotkey launcher")

	ahkPath := sl.findAutoHotkeyExecutable()
	if ahkPath == "" {
		sl.logMessage("ERROR: AutoHotkey executable not found")
		return fmt.Errorf("AutoHotkey executable not found")
	}

	sl.logMessage(fmt.Sprintf("Using AutoHotkey: %s", ahkPath))

	if _, err := os.Stat(sl.scriptsPath); os.IsNotExist(err) {
		sl.logMessage(fmt.Sprintf("ERROR: Scripts directory not found: %s", sl.scriptsPath))
		return fmt.Errorf("scripts directory not found: %s", sl.scriptsPath)
	}

	launchedCount := 0

	err := filepath.Walk(sl.scriptsPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() {
			ext := strings.ToLower(filepath.Ext(path))
			if ext == ".ahk" || ext == ".ahk2" {
				filename := filepath.Base(path)

				if err := sl.launchScript(path, ahkPath); err != nil {
					sl.logMessage(fmt.Sprintf("Failed to launch: %s - %v", filename, err))
				} else {
					sl.logMessage(fmt.Sprintf("Successfully launched: %s", filename))
					launchedCount++
					time.Sleep(200 * time.Millisecond) // Small delay between launches
				}
			}
		}
		return nil
	})

	if err != nil {
		sl.logMessage(fmt.Sprintf("ERROR: %v", err))
		return err
	}

	sl.logMessage(fmt.Sprintf("Launcher completed. Scripts launched: %d", launchedCount))
	return nil
}

func main() {
	var scriptsPath = flag.String("path", "scripts\\startup", "Path to the startup scripts directory")
	var showHelp = flag.Bool("help", false, "Show help message")
	flag.Parse()

	if *showHelp {
		fmt.Println("Elevated AHK Startup Launcher")
		fmt.Println("Usage: ahk-startup-launcher-go.exe [--path <scripts_directory>]")
		fmt.Println("Default path: scripts\\startup")
		return
	}

	launcher, err := NewStartupLauncher(*scriptsPath)
	if err != nil {
		log.Fatalf("Failed to create launcher: %v", err)
	}
	defer launcher.Close()

	if err := launcher.Run(); err != nil {
		log.Fatalf("Launcher failed: %v", err)
	}
}