package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
	"unsafe"

	"github.com/fatih/color"
	"github.com/olekukonko/tablewriter"
	"github.com/shirou/gopsutil/v3/process"
)

// Windows API constants and types for privilege detection
const (
	TOKEN_QUERY = 0x0008
)

var (
	kernel32                = syscall.NewLazyDLL("kernel32.dll")
	advapi32                = syscall.NewLazyDLL("advapi32.dll")
	procOpenProcess         = kernel32.NewProc("OpenProcess")
	procOpenProcessToken    = advapi32.NewProc("OpenProcessToken")
	procGetTokenInformation = advapi32.NewProc("GetTokenInformation")
	procCloseHandle         = kernel32.NewProc("CloseHandle")
)

type TokenElevationType int32

const (
	TokenElevationTypeDefault TokenElevationType = 1
	TokenElevationTypeFull    TokenElevationType = 2
	TokenElevationTypeLimited TokenElevationType = 3
)

const TokenElevationType_ = 18

// ProcessInfo holds information about an AutoHotkey process
type ProcessInfo struct {
	PID        int32   `json:"pid"`
	PPID       int32   `json:"ppid"`
	Name       string  `json:"name"`
	ScriptFile string  `json:"script_file"`
	CPUPercent float64 `json:"cpu_percent"`
	MemoryMB   float64 `json:"memory_mb"`
	VirtualMB  float64 `json:"virtual_mb"`
	CmdLine    string  `json:"cmdline"`
	Privilege  string  `json:"privilege,omitempty"`
}

// Config holds command line configuration
type Config struct {
	Verbose   bool
	Export    string
	NoColor   bool
	SortBy    string
	JSON      bool
	Help      bool
	Privilege bool
}

// Global flag for CPU calculation
var enableCPUCalculation bool

func main() {
	startTime := time.Now()

	config := parseFlags()

	if config.Help {
		printHelp()
		return
	}

	// Initialize colors
	if config.NoColor {
		color.NoColor = true
	}

	// Header
	cyan := color.New(color.FgCyan)
	yellow := color.New(color.FgYellow)
	green := color.New(color.FgGreen)
	red := color.New(color.FgRed)

	if !config.JSON {
		cyan.Println("AutoHotkey Running Scripts Monitor - Optimized")
		cyan.Println("==============================================")
		fmt.Println()
		yellow.Println("Scanning for AutoHotkey processes...")
	}

	// Get AutoHotkey processes with optimized concurrent processing
	processes, err := getAutoHotkeyProcessesOptimized()
	if err != nil {
		red.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	if len(processes) == 0 {
		if !config.JSON {
			yellow.Println("No AutoHotkey processes are currently running.")
		}
		return
	}

	// Detect privileges concurrently if requested
	if config.Privilege {
		detectPrivilegesConcurrently(processes)
	}

	// Sort processes if requested
	sortProcesses(processes, config.SortBy)

	if !config.JSON {
		green.Printf("Found %d running AutoHotkey process(es):\n", len(processes))
		fmt.Println()
	}

	// Output format
	if config.JSON {
		outputJSON(processes)
	} else {
		outputTable(processes, config.Verbose, config.Privilege)
	}

	// Export to file if requested
	if config.Export != "" {
		err := exportToFile(processes, config.Export, config.Verbose, config.Privilege)
		if err != nil {
			red.Printf("Error exporting to file: %v\n", err)
		} else {
			green.Printf("Results exported to: %s\n", config.Export)
		}
	}

	// Show execution time
	elapsed := time.Since(startTime)
	if !config.JSON {
		fmt.Printf("\nExecution time: %dms\n", elapsed.Nanoseconds()/1000000)
	}
}

func parseFlags() Config {
	var config Config

	flag.BoolVar(&config.Verbose, "verbose", false, "Show verbose output including command lines")
	flag.BoolVar(&config.Verbose, "v", false, "Show verbose output including command lines")
	flag.StringVar(&config.Export, "export", "", "Export results to a file")
	flag.StringVar(&config.Export, "e", "", "Export results to a file")
	flag.BoolVar(&config.NoColor, "no-color", false, "Disable colored output")
	flag.StringVar(&config.SortBy, "sort", "pid", "Sort by: pid, name, memory, cpu, script")
	flag.BoolVar(&config.JSON, "json", false, "Output in JSON format")
	flag.BoolVar(&config.Help, "help", false, "Show help information")
	flag.BoolVar(&config.Help, "h", false, "Show help information")
	flag.BoolVar(&config.Privilege, "privilege", false, "Show privilege level (Admin/User)")
	flag.BoolVar(&config.Privilege, "p", false, "Show privilege level (Admin/User)")

	var enableCPU bool
	flag.BoolVar(&enableCPU, "cpu", false, "Enable CPU percentage calculation (slower but more detailed)")

	// Store CPU flag in a global for processAHKProcessOptimized to use
	if enableCPU {
		enableCPUCalculation = true
	}

	flag.Parse()
	return config
}

func printHelp() {
	fmt.Println("AutoHotkey Running Scripts Monitor - Go Version")
	fmt.Println("==============================================")
	fmt.Println()
	fmt.Println("This tool displays all currently running AutoHotkey processes with:")
	fmt.Println("  • Process ID (PID) and Parent PID (PPID)")
	fmt.Println("  • AutoHotkey executable name")
	fmt.Println("  • Script file being executed")
	fmt.Println("  • CPU usage percentage")
	fmt.Println("  • Memory usage (physical and virtual)")
	fmt.Println("  • Privilege level (Admin/User) when --privilege flag is used")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  go run monitor.go [options]")
	fmt.Println("  ./show_running_scripts_detailed [options]")
	fmt.Println()
	fmt.Println("Options:")
	fmt.Println("  -v, --verbose       Show verbose output including command lines")
	fmt.Println("  -e, --export FILE   Export results to a file")
	fmt.Println("  --no-color          Disable colored output")
	fmt.Println("  --sort FIELD        Sort by: pid, name, memory, cpu, script")
	fmt.Println("  --json              Output in JSON format")
	fmt.Println("  -p, --privilege     Show privilege level (Admin/User)")
	fmt.Println("  --cpu               Enable CPU percentage calculation (slower but more detailed)")
	fmt.Println("  -h, --help          Show this help message")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  go run monitor.go")
	fmt.Println("  go run monitor.go --verbose")
	fmt.Println("  go run monitor.go --sort memory")
	fmt.Println("  go run monitor.go --export results.txt")
	fmt.Println("  go run monitor.go --json")
	fmt.Println("  go run monitor.go --privilege")
}

// getProcessPrivilege determines if a process is running with elevated privileges
func getProcessPrivilege(pid int32) string {
	// Open process with PROCESS_QUERY_INFORMATION access
	handle, _, _ := procOpenProcess.Call(uintptr(0x0400), 0, uintptr(pid))
	if handle == 0 {
		return "Unknown"
	}
	defer procCloseHandle.Call(handle)

	// Open process token
	var token syscall.Handle
	ret, _, _ := procOpenProcessToken.Call(handle, TOKEN_QUERY, uintptr(unsafe.Pointer(&token)))
	if ret == 0 {
		return "Unknown"
	}
	defer procCloseHandle.Call(uintptr(token))

	// Get token elevation type
	var elevationType TokenElevationType
	var returnLength uint32
	ret, _, _ = procGetTokenInformation.Call(
		uintptr(token),
		TokenElevationType_,
		uintptr(unsafe.Pointer(&elevationType)),
		unsafe.Sizeof(elevationType),
		uintptr(unsafe.Pointer(&returnLength)),
	)
	if ret == 0 {
		return "Unknown"
	}

	switch elevationType {
	case TokenElevationTypeFull:
		return "Admin"
	case TokenElevationTypeLimited:
		return "User"
	case TokenElevationTypeDefault:
		return "User"
	default:
		return "Unknown"
	}
}

// Optimized version with concurrent processing and reduced allocations
func getAutoHotkeyProcessesOptimized() ([]ProcessInfo, error) {
	// Get all processes
	processes, err := process.Processes()
	if err != nil {
		return nil, fmt.Errorf("failed to get processes: %w", err)
	}

	// Pre-allocate with estimated capacity to reduce allocations
	ahkProcesses := make([]*process.Process, 0, 16)

	// Pre-filter AutoHotkey processes with optimized string matching
	for _, proc := range processes {
		name, err := proc.Name()
		if err != nil {
			continue
		}
		// Avoid ToLower allocation by checking common patterns directly
		if containsAutoHotkey(name) {
			ahkProcesses = append(ahkProcesses, proc)
		}
	}

	if len(ahkProcesses) == 0 {
		return []ProcessInfo{}, nil
	}

	// Pre-allocate result slice with exact capacity
	autohotkeyProcesses := make([]ProcessInfo, 0, len(ahkProcesses))
	var mu sync.Mutex
	var wg sync.WaitGroup

	// Optimize worker count based on process count and CPU cores
	maxWorkers := 8
	if len(ahkProcesses) < maxWorkers {
		maxWorkers = len(ahkProcesses)
	}

	processChan := make(chan *process.Process, len(ahkProcesses))

	// Start workers
	for i := 0; i < maxWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for proc := range processChan {
				if processInfo := processAHKProcessOptimized(proc); processInfo != nil {
					mu.Lock()
					autohotkeyProcesses = append(autohotkeyProcesses, *processInfo)
					mu.Unlock()
				}
			}
		}()
	}

	// Send processes to workers
	for _, proc := range ahkProcesses {
		processChan <- proc
	}
	close(processChan)

	wg.Wait()
	return autohotkeyProcesses, nil
}

// Fast AutoHotkey name detection without string allocation
func containsAutoHotkey(name string) bool {
	// Check common patterns without ToLower allocation
	return strings.Contains(name, "AutoHotkey") ||
		   strings.Contains(name, "autohotkey") ||
		   strings.Contains(name, "AUTOHOTKEY") ||
		   strings.Contains(name, "AutoHotKey") ||
		   strings.Contains(name, "autohotKey")
}

// Process individual AutoHotkey process with optimized syscalls
func processAHKProcessOptimized(proc *process.Process) *ProcessInfo {
	name, err := proc.Name()
	if err != nil {
		return nil
	}

	pid := proc.Pid

	ppid, err := proc.Ppid()
	if err != nil {
		ppid = 0
	}

	// Conditionally calculate CPU percentage based on flag
	var cpuPercent float64 = 0
	if enableCPUCalculation {
		if cpu, err := proc.CPUPercent(); err == nil {
			cpuPercent = cpu
		}
	}

	// Get memory information
	memInfo, err := proc.MemoryInfo()
	if err != nil {
		return nil
	}

	// Use bit shifting for faster division (1024 = 2^10, 1024*1024 = 2^20)
	memoryMB := float64(memInfo.RSS) / (1 << 20)
	virtualMB := float64(memInfo.VMS) / (1 << 20)

	// Get command line
	cmdline, err := proc.Cmdline()
	if err != nil {
		cmdline = ""
	}

	// Extract script filename
	scriptFile := extractScriptFilenameOptimized(cmdline)

	return &ProcessInfo{
		PID:        pid,
		PPID:       ppid,
		Name:       name,
		ScriptFile: scriptFile,
		CPUPercent: cpuPercent,
		MemoryMB:   memoryMB,
		VirtualMB:  virtualMB,
		CmdLine:    cmdline,
	}
}

// Optimized concurrent privilege detection with worker pool
func detectPrivilegesConcurrently(processes []ProcessInfo) {
	if len(processes) == 0 {
		return
	}

	var wg sync.WaitGroup

	// Use smaller worker pool for privilege detection to reduce syscall contention
	maxWorkers := 4
	if len(processes) < maxWorkers {
		maxWorkers = len(processes)
	}

	type privilegeJob struct {
		index int
		pid   int32
	}

	jobChan := make(chan privilegeJob, len(processes))

	// Start workers
	for i := 0; i < maxWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for job := range jobChan {
				processes[job.index].Privilege = getProcessPrivilege(job.pid)
			}
		}()
	}

	// Send jobs to workers
	for i := range processes {
		jobChan <- privilegeJob{index: i, pid: processes[i].PID}
	}
	close(jobChan)

	wg.Wait()
}

// Highly optimized script filename extraction with minimal allocations
func extractScriptFilenameOptimized(cmdline string) string {
	if cmdline == "" {
		return "Unknown"
	}

	// Fast path: check for .ahk extensions without ToLower allocation
	if !containsAHKExtension(cmdline) {
		return "Unknown"
	}

	// Handle quoted arguments - optimized version with byte scanning
	if strings.Contains(cmdline, "\"") {
		return extractFromQuotedArgs(cmdline)
	}

	// Optimized field splitting - scan for .ahk files directly
	return extractFromFields(cmdline)
}

// Fast extension check without string allocation
func containsAHKExtension(s string) bool {
	return strings.Contains(s, ".ahk") || strings.Contains(s, ".AHK")
}

// Extract script from quoted arguments with minimal allocations
func extractFromQuotedArgs(cmdline string) string {
	inQuote := false
	start := 0

	for i, char := range cmdline {
		if char == '"' {
			if inQuote {
				// End of quoted section
				part := cmdline[start:i]
				if hasAHKExtension(part) {
					return filepath.Base(part)
				}
				inQuote = false
			} else {
				// Start of quoted section
				start = i + 1
				inQuote = true
			}
		}
	}

	// Fallback to field extraction
	return extractFromFields(cmdline)
}

// Extract from space-separated fields
func extractFromFields(cmdline string) string {
	// Use strings.Fields once and scan efficiently
	args := strings.Fields(cmdline)
	for _, arg := range args {
		cleaned := strings.Trim(arg, "\"")
		if hasAHKExtension(cleaned) {
			return filepath.Base(cleaned)
		}
	}

	// Final fallback: look for any file argument that might be a script
	for i, arg := range args {
		if i > 0 && !strings.HasPrefix(arg, "-") {
			cleaned := strings.Trim(arg, "\"")
			if strings.ContainsAny(cleaned, "\\/") {
				return filepath.Base(cleaned)
			}
		}
	}

	return "Unknown"
}

// Fast suffix check without ToLower allocation
func hasAHKExtension(s string) bool {
	sLen := len(s)
	if sLen < 4 {
		return false
	}

	// Check last 4 characters for .ahk (case insensitive)
	suffix := s[sLen-4:]
	return strings.EqualFold(suffix, ".ahk") ||
		   (sLen >= 5 && strings.EqualFold(s[sLen-5:], ".ahk2"))
}

func sortProcesses(processes []ProcessInfo, sortBy string) {
	switch sortBy {
	case "name":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].Name < processes[j].Name
		})
	case "memory":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].MemoryMB > processes[j].MemoryMB
		})
	case "cpu":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].CPUPercent > processes[j].CPUPercent
		})
	case "script":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].ScriptFile < processes[j].ScriptFile
		})
	default: // "pid" or any other value
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].PID < processes[j].PID
		})
	}
}

func outputTable(processes []ProcessInfo, verbose bool, showPrivilege bool) {
	table := tablewriter.NewWriter(os.Stdout)

	// Set headers based on whether privilege column is requested
	var headers []string
	if showPrivilege {
		headers = []string{"PID", "PPID", "Name", "Script File", "CPU %", "Memory (MB)", "Virtual (MB)", "Privilege"}
	} else {
		headers = []string{"PID", "PPID", "Name", "Script File", "CPU %", "Memory (MB)", "Virtual (MB)"}
	}

	table.SetHeader(headers)
	table.SetBorder(true)
	table.SetRowLine(true)

	for _, proc := range processes {
		row := []string{
			strconv.Itoa(int(proc.PID)),
			strconv.Itoa(int(proc.PPID)),
			proc.Name,
			proc.ScriptFile,
			fmt.Sprintf("%.2f", proc.CPUPercent),
			fmt.Sprintf("%.1f", proc.MemoryMB),
			fmt.Sprintf("%.1f", proc.VirtualMB),
		}

		// Add privilege column if requested
		if showPrivilege {
			row = append(row, proc.Privilege)
		}

		table.Append(row)
	}

	table.Render()

	if verbose {
		fmt.Println("\nDetailed Command Lines:")
		fmt.Println(strings.Repeat("=", 50))
		for _, proc := range processes {
			fmt.Printf("PID %d: %s\n", proc.PID, proc.CmdLine)
		}
	}
}

func outputJSON(processes []ProcessInfo) {
	jsonData, err := json.MarshalIndent(processes, "", "  ")
	if err != nil {
		red := color.New(color.FgRed)
		red.Printf("Error encoding JSON: %v\n", err)
		return
	}
	fmt.Println(string(jsonData))
}

func exportToFile(processes []ProcessInfo, filename string, verbose bool, showPrivilege bool) error {
	file, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer file.Close()

	// Write header
	fmt.Fprintf(file, "AutoHotkey Running Scripts Monitor - Detailed View\n")
	fmt.Fprintf(file, "Generated: %s\n", time.Now().Format("2006-01-02 15:04:05"))
	fmt.Fprintf(file, "======================================================\n\n")
	fmt.Fprintf(file, "Found %d running AutoHotkey process(es):\n\n", len(processes))

	// Create table for file output
	table := tablewriter.NewWriter(file)

	// Set headers based on whether privilege column is requested
	var headers []string
	if showPrivilege {
		headers = []string{"PID", "PPID", "Name", "Script File", "CPU %", "Memory (MB)", "Virtual (MB)", "Privilege"}
	} else {
		headers = []string{"PID", "PPID", "Name", "Script File", "CPU %", "Memory (MB)", "Virtual (MB)"}
	}

	table.SetHeader(headers)
	table.SetBorder(true)
	table.SetRowLine(true)

	for _, proc := range processes {
		row := []string{
			strconv.Itoa(int(proc.PID)),
			strconv.Itoa(int(proc.PPID)),
			proc.Name,
			proc.ScriptFile,
			fmt.Sprintf("%.2f", proc.CPUPercent),
			fmt.Sprintf("%.1f", proc.MemoryMB),
			fmt.Sprintf("%.1f", proc.VirtualMB),
		}

		// Add privilege column if requested
		if showPrivilege {
			row = append(row, proc.Privilege)
		}

		table.Append(row)
	}

	table.Render()

	if verbose {
		fmt.Fprintf(file, "\nDetailed Command Lines:\n")
		fmt.Fprintf(file, "%s\n", strings.Repeat("=", 50))
		for _, proc := range processes {
			fmt.Fprintf(file, "PID %d: %s\n", proc.PID, proc.CmdLine)
		}
	}

	return nil
}
