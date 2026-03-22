package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"log"
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

// Enhanced ProcessInfo with additional monitoring capabilities
type ProcessInfo struct {
	PID         int32     `json:"pid"`
	PPID        int32     `json:"ppid"`
	Name        string    `json:"name"`
	ScriptFile  string    `json:"script_file"`
	CPUPercent  float64   `json:"cpu_percent"`
	MemoryMB    float64   `json:"memory_mb"`
	VirtualMB   float64   `json:"virtual_mb"`
	CmdLine     string    `json:"cmdline"`
	Privilege   string    `json:"privilege,omitempty"`
	StartTime   time.Time `json:"start_time"`
	Runtime     string    `json:"runtime"`
	Status      string    `json:"status"`
	ThreadCount int32     `json:"thread_count"`
	HandleCount int32     `json:"handle_count,omitempty"`
	WorkingDir  string    `json:"working_dir,omitempty"`
	Username    string    `json:"username,omitempty"`
}

// Enhanced Config with additional monitoring options
type Config struct {
	Verbose     bool
	Export      string
	NoColor     bool
	SortBy      string
	JSON        bool
	Help        bool
	Privilege   bool
	Watch       bool
	WatchDelay  int
	Detailed    bool
	Filter      string
	LogFile     string
	Continuous  bool
	MaxResults  int
	ShowThreads bool
	ShowHandles bool
}

// Global flags
var (
	enableCPUCalculation bool
	logger              *log.Logger
)

// Statistics tracking for enhanced monitoring
type MonitorStats struct {
	TotalScans       int
	ProcessesFound   int
	LastScanTime     time.Time
	AverageProcesses float64
	PeakProcesses    int
	StartTime        time.Time
}

var stats MonitorStats

func main() {
	startTime := time.Now()
	stats.StartTime = startTime

	config := parseFlags()

	if config.Help {
		printEnhancedHelp()
		return
	}

	// Initialize logging if requested
	if config.LogFile != "" {
		initLogging(config.LogFile)
	}

	// Initialize colors
	if config.NoColor {
		color.NoColor = true
	}

	// Watch mode for continuous monitoring
	if config.Watch {
		runWatchMode(config)
		return
	}

	// Continuous mode for logging
	if config.Continuous {
		runContinuousMode(config)
		return
	}

	// Single scan mode
	runSingleScan(config, startTime)
}

func parseFlags() Config {
	var config Config

	flag.BoolVar(&config.Verbose, "verbose", false, "Show verbose output including command lines")
	flag.BoolVar(&config.Verbose, "v", false, "Show verbose output including command lines")
	flag.StringVar(&config.Export, "export", "", "Export results to a file")
	flag.StringVar(&config.Export, "e", "", "Export results to a file")
	flag.BoolVar(&config.NoColor, "no-color", false, "Disable colored output")
	flag.StringVar(&config.SortBy, "sort", "pid", "Sort by: pid, name, memory, cpu, script, runtime, threads")
	flag.BoolVar(&config.JSON, "json", false, "Output in JSON format")
	flag.BoolVar(&config.Help, "help", false, "Show help information")
	flag.BoolVar(&config.Help, "h", false, "Show help information")
	flag.BoolVar(&config.Privilege, "privilege", false, "Show privilege level (Admin/User)")
	flag.BoolVar(&config.Privilege, "p", false, "Show privilege level (Admin/User)")
	flag.BoolVar(&config.Watch, "watch", false, "Watch mode - continuously monitor processes")
	flag.BoolVar(&config.Watch, "w", false, "Watch mode - continuously monitor processes")
	flag.IntVar(&config.WatchDelay, "delay", 2, "Delay between scans in watch mode (seconds)")
	flag.BoolVar(&config.Detailed, "detailed", false, "Show detailed process information")
	flag.BoolVar(&config.Detailed, "d", false, "Show detailed process information")
	flag.StringVar(&config.Filter, "filter", "", "Filter processes by script name pattern")
	flag.StringVar(&config.LogFile, "log", "", "Log output to file")
	flag.BoolVar(&config.Continuous, "continuous", false, "Run continuously and log to file")
	flag.IntVar(&config.MaxResults, "max", 0, "Maximum number of results to show (0 = unlimited)")
	flag.BoolVar(&config.ShowThreads, "threads", false, "Show thread count information")
	flag.BoolVar(&config.ShowHandles, "handles", false, "Show handle count information (Windows only)")

	var enableCPU bool
	flag.BoolVar(&enableCPU, "cpu", false, "Enable CPU percentage calculation (slower but more detailed)")

	if enableCPU {
		enableCPUCalculation = true
	}

	flag.Parse()
	return config
}

func initLogging(logFile string) {
	file, err := os.OpenFile(logFile, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		fmt.Printf("Error opening log file: %v\n", err)
		os.Exit(1)
	}
	logger = log.New(file, "", log.LstdFlags)
}

func runSingleScan(config Config, startTime time.Time) {
	cyan := color.New(color.FgCyan)
	yellow := color.New(color.FgYellow)
	green := color.New(color.FgGreen)
	red := color.New(color.FgRed)

	if !config.JSON {
		cyan.Println("AutoHotkey Enhanced Monitor (GO) - Advanced Process Tracking")
		cyan.Println("=====================================================")
		fmt.Println()
		yellow.Println("Scanning for AutoHotkey processes...")
	}

	processes, err := getEnhancedAutoHotkeyProcesses(config)
	if err != nil {
		red.Printf("Error: %v\n", err)
		os.Exit(1)
	}

	updateStats(len(processes))

	if len(processes) == 0 {
		if !config.JSON {
			yellow.Println("No AutoHotkey processes are currently running.")
		}
		return
	}

	// Apply filters
	if config.Filter != "" {
		processes = filterProcesses(processes, config.Filter)
	}

	// Limit results if requested
	if config.MaxResults > 0 && len(processes) > config.MaxResults {
		processes = processes[:config.MaxResults]
	}

	// Detect privileges concurrently if requested
	if config.Privilege {
		detectPrivilegesConcurrently(processes)
	}

	// Sort processes
	sortEnhancedProcesses(processes, config.SortBy)

	if !config.JSON {
		green.Printf("Found %d running AutoHotkey process(es):\n", len(processes))
		fmt.Println()
	}

	// Output format
	if config.JSON {
		outputEnhancedJSON(processes, &stats)
	} else {
		outputEnhancedTable(processes, config)
		showEnhancedStats(config)
	}

	// Export to file if requested
	if config.Export != "" {
		err := exportEnhancedToFile(processes, config)
		if err != nil {
			red.Printf("Error exporting to file: %v\n", err)
		} else {
			green.Printf("Results exported to: %s\n", config.Export)
		}
	}

	// Log if logger is available
	if logger != nil {
		logger.Printf("Scan completed: %d processes found", len(processes))
	}

	elapsed := time.Since(startTime)
	if !config.JSON {
		fmt.Printf("\nExecution time: %dms\n", elapsed.Nanoseconds()/1000000)
	}
}

func runWatchMode(config Config) {
	cyan := color.New(color.FgCyan)
	yellow := color.New(color.FgYellow)

	cyan.Println("AutoHotkey Enhanced Monitor - Watch Mode")
	cyan.Println("======================================")
	yellow.Printf("Monitoring every %d seconds. Press Ctrl+C to stop.\n\n", config.WatchDelay)

	for {
		// Clear screen (Windows compatible)
		fmt.Print("\033[2J\033[H")

		cyan.Printf("Scan Time: %s\n", time.Now().Format("2006-01-02 15:04:05"))
		fmt.Println()

		processes, err := getEnhancedAutoHotkeyProcesses(config)
		if err != nil {
			fmt.Printf("Error: %v\n", err)
			time.Sleep(time.Duration(config.WatchDelay) * time.Second)
			continue
		}

		updateStats(len(processes))

		if config.Filter != "" {
			processes = filterProcesses(processes, config.Filter)
		}

		if config.MaxResults > 0 && len(processes) > config.MaxResults {
			processes = processes[:config.MaxResults]
		}

		if config.Privilege {
			detectPrivilegesConcurrently(processes)
		}

		sortEnhancedProcesses(processes, config.SortBy)

		if len(processes) == 0 {
			yellow.Println("No AutoHotkey processes are currently running.")
		} else {
			outputEnhancedTable(processes, config)
		}

		showEnhancedStats(config)

		if logger != nil {
			logger.Printf("Watch scan: %d processes found", len(processes))
		}

		time.Sleep(time.Duration(config.WatchDelay) * time.Second)
	}
}

func runContinuousMode(config Config) {
	if config.LogFile == "" {
		fmt.Println("Continuous mode requires --log flag to specify log file")
		os.Exit(1)
	}

	fmt.Printf("Running in continuous mode, logging to: %s\n", config.LogFile)
	fmt.Println("Press Ctrl+C to stop.")

	for {
		processes, err := getEnhancedAutoHotkeyProcesses(config)
		if err != nil {
			if logger != nil {
				logger.Printf("Error scanning processes: %v", err)
			}
			time.Sleep(time.Duration(config.WatchDelay) * time.Second)
			continue
		}

		updateStats(len(processes))

		if config.Filter != "" {
			processes = filterProcesses(processes, config.Filter)
		}

		if logger != nil {
			logger.Printf("Continuous scan: %d processes found", len(processes))
			for _, proc := range processes {
				logger.Printf("Process: PID=%d, Script=%s, Memory=%.1fMB, Runtime=%s",
					proc.PID, proc.ScriptFile, proc.MemoryMB, proc.Runtime)
			}
		}

		time.Sleep(time.Duration(config.WatchDelay) * time.Second)
	}
}

func getEnhancedAutoHotkeyProcesses(config Config) ([]ProcessInfo, error) {
	processes, err := process.Processes()
	if err != nil {
		return nil, fmt.Errorf("failed to get processes: %w", err)
	}

	ahkProcesses := make([]*process.Process, 0, 16)

	for _, proc := range processes {
		name, err := proc.Name()
		if err != nil {
			continue
		}
		if containsAutoHotkey(name) {
			ahkProcesses = append(ahkProcesses, proc)
		}
	}

	if len(ahkProcesses) == 0 {
		return []ProcessInfo{}, nil
	}

	autohotkeyProcesses := make([]ProcessInfo, 0, len(ahkProcesses))
	var mu sync.Mutex
	var wg sync.WaitGroup

	maxWorkers := 8
	if len(ahkProcesses) < maxWorkers {
		maxWorkers = len(ahkProcesses)
	}

	processChan := make(chan *process.Process, len(ahkProcesses))

	for i := 0; i < maxWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for proc := range processChan {
				if processInfo := processEnhancedAHKProcess(proc, config); processInfo != nil {
					mu.Lock()
					autohotkeyProcesses = append(autohotkeyProcesses, *processInfo)
					mu.Unlock()
				}
			}
		}()
	}

	for _, proc := range ahkProcesses {
		processChan <- proc
	}
	close(processChan)

	wg.Wait()
	return autohotkeyProcesses, nil
}

func processEnhancedAHKProcess(proc *process.Process, config Config) *ProcessInfo {
	name, err := proc.Name()
	if err != nil {
		return nil
	}

	pid := proc.Pid

	ppid, err := proc.Ppid()
	if err != nil {
		ppid = 0
	}

	var cpuPercent float64 = 0
	if enableCPUCalculation {
		if cpu, err := proc.CPUPercent(); err == nil {
			cpuPercent = cpu
		}
	}

	memInfo, err := proc.MemoryInfo()
	if err != nil {
		return nil
	}

	memoryMB := float64(memInfo.RSS) / (1 << 20)
	virtualMB := float64(memInfo.VMS) / (1 << 20)

	cmdline, err := proc.Cmdline()
	if err != nil {
		cmdline = ""
	}

	scriptFile := extractScriptFilenameOptimized(cmdline)

	// Enhanced information
	startTime := time.Time{}
	if createTime, err := proc.CreateTime(); err == nil {
		startTime = time.Unix(createTime/1000, 0)
	}

	runtime := ""
	if !startTime.IsZero() {
		runtime = formatDuration(time.Since(startTime))
	}

	status := "Running"
	if procStatus, err := proc.Status(); err == nil && len(procStatus) > 0 {
		status = procStatus[0]
	}

	var threadCount int32 = 0
	if config.ShowThreads {
		if threads, err := proc.NumThreads(); err == nil {
			threadCount = threads
		}
	}

	var handleCount int32 = 0
	if config.ShowHandles {
		// Handle count is Windows-specific and requires additional syscalls
		handleCount = getProcessHandleCount(pid)
	}

	workingDir := ""
	if config.Detailed {
		if cwd, err := proc.Cwd(); err == nil {
			workingDir = cwd
		}
	}

	username := ""
	if config.Detailed {
		if user, err := proc.Username(); err == nil {
			username = user
		}
	}

	return &ProcessInfo{
		PID:         pid,
		PPID:        ppid,
		Name:        name,
		ScriptFile:  scriptFile,
		CPUPercent:  cpuPercent,
		MemoryMB:    memoryMB,
		VirtualMB:   virtualMB,
		CmdLine:     cmdline,
		StartTime:   startTime,
		Runtime:     runtime,
		Status:      status,
		ThreadCount: threadCount,
		HandleCount: handleCount,
		WorkingDir:  workingDir,
		Username:    username,
	}
}

func getProcessHandleCount(pid int32) int32 {
	// Windows-specific handle count retrieval
	// This is a simplified implementation
	return 0 // Placeholder - would need additional Windows API calls
}

func formatDuration(d time.Duration) string {
	if d < time.Minute {
		return fmt.Sprintf("%.0fs", d.Seconds())
	} else if d < time.Hour {
		return fmt.Sprintf("%.0fm%.0fs", d.Minutes(), d.Seconds()-60*d.Minutes())
	} else if d < 24*time.Hour {
		hours := int(d.Hours())
		minutes := int(d.Minutes()) - 60*hours
		return fmt.Sprintf("%dh%dm", hours, minutes)
	} else {
		days := int(d.Hours()) / 24
		hours := int(d.Hours()) - 24*days
		return fmt.Sprintf("%dd%dh", days, hours)
	}
}

func updateStats(processCount int) {
	stats.TotalScans++
	stats.ProcessesFound = processCount
	stats.LastScanTime = time.Now()

	if processCount > stats.PeakProcesses {
		stats.PeakProcesses = processCount
	}

	// Calculate running average
	if stats.TotalScans == 1 {
		stats.AverageProcesses = float64(processCount)
	} else {
		stats.AverageProcesses = (stats.AverageProcesses*float64(stats.TotalScans-1) + float64(processCount)) / float64(stats.TotalScans)
	}
}

func filterProcesses(processes []ProcessInfo, filter string) []ProcessInfo {
	if filter == "" {
		return processes
	}

	filtered := make([]ProcessInfo, 0)
	filterLower := strings.ToLower(filter)

	for _, proc := range processes {
		if strings.Contains(strings.ToLower(proc.ScriptFile), filterLower) ||
		   strings.Contains(strings.ToLower(proc.Name), filterLower) {
			filtered = append(filtered, proc)
		}
	}

	return filtered
}

func sortEnhancedProcesses(processes []ProcessInfo, sortBy string) {
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
	case "runtime":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].StartTime.Before(processes[j].StartTime)
		})
	case "threads":
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].ThreadCount > processes[j].ThreadCount
		})
	default: // "pid" or any other value
		sort.Slice(processes, func(i, j int) bool {
			return processes[i].PID < processes[j].PID
		})
	}
}

func outputEnhancedTable(processes []ProcessInfo, config Config) {
	table := tablewriter.NewWriter(os.Stdout)

	// Build headers dynamically based on config
	headers := []string{"PID", "PPID", "Name", "Script File"}

	if enableCPUCalculation {
		headers = append(headers, "CPU %")
	}

	headers = append(headers, "Memory (MB)", "Virtual (MB)")

	if config.ShowThreads {
		headers = append(headers, "Threads")
	}

	if config.ShowHandles {
		headers = append(headers, "Handles")
	}

	headers = append(headers, "Runtime", "Status")

	if config.Privilege {
		headers = append(headers, "Privilege")
	}

	if config.Detailed {
		headers = append(headers, "Username", "Working Dir")
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
		}

		if enableCPUCalculation {
			row = append(row, fmt.Sprintf("%.2f", proc.CPUPercent))
		}

		row = append(row,
			fmt.Sprintf("%.1f", proc.MemoryMB),
			fmt.Sprintf("%.1f", proc.VirtualMB),
		)

		if config.ShowThreads {
			row = append(row, strconv.Itoa(int(proc.ThreadCount)))
		}

		if config.ShowHandles {
			row = append(row, strconv.Itoa(int(proc.HandleCount)))
		}

		row = append(row, proc.Runtime, proc.Status)

		if config.Privilege {
			row = append(row, proc.Privilege)
		}

		if config.Detailed {
			row = append(row, proc.Username, proc.WorkingDir)
		}

		table.Append(row)
	}

	table.Render()

	if config.Verbose {
		fmt.Println("\nDetailed Command Lines:")
		fmt.Println(strings.Repeat("=", 50))
		for _, proc := range processes {
			fmt.Printf("PID %d: %s\n", proc.PID, proc.CmdLine)
		}
	}
}

func outputEnhancedJSON(processes []ProcessInfo, stats *MonitorStats) {
	output := struct {
		Timestamp time.Time     `json:"timestamp"`
		Stats     MonitorStats  `json:"stats"`
		Processes []ProcessInfo `json:"processes"`
	}{
		Timestamp: time.Now(),
		Stats:     *stats,
		Processes: processes,
	}

	jsonData, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		red := color.New(color.FgRed)
		red.Printf("Error encoding JSON: %v\n", err)
		return
	}
	fmt.Println(string(jsonData))
}

func showEnhancedStats(config Config) {
	if config.JSON {
		return
	}

	blue := color.New(color.FgBlue)
	fmt.Println()
	blue.Println("Monitor Statistics:")
	blue.Println("==================")
	fmt.Printf("Total Scans: %d\n", stats.TotalScans)
	fmt.Printf("Current Processes: %d\n", stats.ProcessesFound)
	fmt.Printf("Peak Processes: %d\n", stats.PeakProcesses)
	fmt.Printf("Average Processes: %.1f\n", stats.AverageProcesses)
	fmt.Printf("Monitor Uptime: %s\n", formatDuration(time.Since(stats.StartTime)))
	if !stats.LastScanTime.IsZero() {
		fmt.Printf("Last Scan: %s\n", stats.LastScanTime.Format("15:04:05"))
	}
}

func exportEnhancedToFile(processes []ProcessInfo, config Config) error {
	file, err := os.Create(config.Export)
	if err != nil {
		return err
	}
	defer file.Close()

	fmt.Fprintf(file, "AutoHotkey Enhanced Monitor - Detailed Report\n")
	fmt.Fprintf(file, "Generated: %s\n", time.Now().Format("2006-01-02 15:04:05"))
	fmt.Fprintf(file, "============================================\n\n")

	// Export stats
	fmt.Fprintf(file, "Monitor Statistics:\n")
	fmt.Fprintf(file, "Total Scans: %d\n", stats.TotalScans)
	fmt.Fprintf(file, "Peak Processes: %d\n", stats.PeakProcesses)
	fmt.Fprintf(file, "Average Processes: %.1f\n", stats.AverageProcesses)
	fmt.Fprintf(file, "Monitor Uptime: %s\n\n", formatDuration(time.Since(stats.StartTime)))

	fmt.Fprintf(file, "Found %d running AutoHotkey process(es):\n\n", len(processes))

	// Create enhanced table for file output
	table := tablewriter.NewWriter(file)

	headers := []string{"PID", "PPID", "Name", "Script File"}
	if enableCPUCalculation {
		headers = append(headers, "CPU %")
	}
	headers = append(headers, "Memory (MB)", "Virtual (MB)", "Runtime", "Status")
	if config.Privilege {
		headers = append(headers, "Privilege")
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
		}

		if enableCPUCalculation {
			row = append(row, fmt.Sprintf("%.2f", proc.CPUPercent))
		}

		row = append(row,
			fmt.Sprintf("%.1f", proc.MemoryMB),
			fmt.Sprintf("%.1f", proc.VirtualMB),
			proc.Runtime,
			proc.Status,
		)

		if config.Privilege {
			row = append(row, proc.Privilege)
		}

		table.Append(row)
	}

	table.Render()

	if config.Verbose {
		fmt.Fprintf(file, "\nDetailed Command Lines:\n")
		fmt.Fprintf(file, "%s\n", strings.Repeat("=", 50))
		for _, proc := range processes {
			fmt.Fprintf(file, "PID %d: %s\n", proc.PID, proc.CmdLine)
		}
	}

	if config.Detailed {
		fmt.Fprintf(file, "\nDetailed Process Information:\n")
		fmt.Fprintf(file, "%s\n", strings.Repeat("=", 50))
		for _, proc := range processes {
			fmt.Fprintf(file, "PID %d (%s):\n", proc.PID, proc.ScriptFile)
			fmt.Fprintf(file, "  Start Time: %s\n", proc.StartTime.Format("2006-01-02 15:04:05"))
			fmt.Fprintf(file, "  Runtime: %s\n", proc.Runtime)
			fmt.Fprintf(file, "  Status: %s\n", proc.Status)
			if proc.Username != "" {
				fmt.Fprintf(file, "  Username: %s\n", proc.Username)
			}
			if proc.WorkingDir != "" {
				fmt.Fprintf(file, "  Working Directory: %s\n", proc.WorkingDir)
			}
			if proc.ThreadCount > 0 {
				fmt.Fprintf(file, "  Thread Count: %d\n", proc.ThreadCount)
			}
			fmt.Fprintf(file, "\n")
		}
	}

	return nil
}

func printEnhancedHelp() {
	fmt.Println("AutoHotkey Enhanced Monitor - Advanced Process Tracking")
	fmt.Println("======================================================")
	fmt.Println()
	fmt.Println("Enhanced monitoring tool for AutoHotkey processes with advanced features:")
	fmt.Println("  • Real-time process monitoring with watch mode")
	fmt.Println("  • Continuous logging capabilities")
	fmt.Println("  • Enhanced process information (runtime, threads, handles)")
	fmt.Println("  • Process filtering and advanced sorting")
	fmt.Println("  • Detailed statistics tracking")
	fmt.Println("  • Privilege detection and user information")
	fmt.Println("  • Flexible export options")
	fmt.Println()
	fmt.Println("Usage:")
	fmt.Println("  go run monitor-enhanced.go [options]")
	fmt.Println()
	fmt.Println("Basic Options:")
	fmt.Println("  -v, --verbose       Show verbose output including command lines")
	fmt.Println("  -e, --export FILE   Export results to a file")
	fmt.Println("  --no-color          Disable colored output")
	fmt.Println("  --sort FIELD        Sort by: pid, name, memory, cpu, script, runtime, threads")
	fmt.Println("  --json              Output in JSON format with statistics")
	fmt.Println("  -h, --help          Show this help message")
	fmt.Println()
	fmt.Println("Enhanced Options:")
	fmt.Println("  -w, --watch         Watch mode - continuously monitor processes")
	fmt.Println("  --delay SECONDS     Delay between scans in watch mode (default: 2)")
	fmt.Println("  -d, --detailed      Show detailed process information")
	fmt.Println("  --filter PATTERN    Filter processes by script name pattern")
	fmt.Println("  --log FILE          Log output to file")
	fmt.Println("  --continuous        Run continuously and log to file")
	fmt.Println("  --max NUMBER        Maximum number of results to show")
	fmt.Println("  --threads           Show thread count information")
	fmt.Println("  --handles           Show handle count information (Windows)")
	fmt.Println()
	fmt.Println("Privilege & Performance:")
	fmt.Println("  -p, --privilege     Show privilege level (Admin/User)")
	fmt.Println("  --cpu               Enable CPU percentage calculation (slower)")
	fmt.Println()
	fmt.Println("Examples:")
	fmt.Println("  go run monitor-enhanced.go")
	fmt.Println("  go run monitor-enhanced.go --watch --delay 5")
	fmt.Println("  go run monitor-enhanced.go --detailed --privilege --threads")
	fmt.Println("  go run monitor-enhanced.go --filter \"script.ahk\" --sort memory")
	fmt.Println("  go run monitor-enhanced.go --continuous --log monitor.log")
	fmt.Println("  go run monitor-enhanced.go --json --export results.json")
}

// Reuse optimized functions from original monitor.go
func containsAutoHotkey(name string) bool {
	return strings.Contains(name, "AutoHotkey") ||
		   strings.Contains(name, "autohotkey") ||
		   strings.Contains(name, "AUTOHOTKEY") ||
		   strings.Contains(name, "AutoHotKey") ||
		   strings.Contains(name, "autohotKey")
}

func extractScriptFilenameOptimized(cmdline string) string {
	if cmdline == "" {
		return "Unknown"
	}

	if !containsAHKExtension(cmdline) {
		return "Unknown"
	}

	if strings.Contains(cmdline, "\"") {
		return extractFromQuotedArgs(cmdline)
	}

	return extractFromFields(cmdline)
}

func containsAHKExtension(s string) bool {
	return strings.Contains(s, ".ahk") || strings.Contains(s, ".AHK")
}

func extractFromQuotedArgs(cmdline string) string {
	inQuote := false
	start := 0

	for i, char := range cmdline {
		if char == '"' {
			if inQuote {
				part := cmdline[start:i]
				if hasAHKExtension(part) {
					return filepath.Base(part)
				}
				inQuote = false
			} else {
				start = i + 1
				inQuote = true
			}
		}
	}

	return extractFromFields(cmdline)
}

func extractFromFields(cmdline string) string {
	args := strings.Fields(cmdline)
	for _, arg := range args {
		cleaned := strings.Trim(arg, "\"")
		if hasAHKExtension(cleaned) {
			return filepath.Base(cleaned)
		}
	}

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

func hasAHKExtension(s string) bool {
	sLen := len(s)
	if sLen < 4 {
		return false
	}

	suffix := s[sLen-4:]
	return strings.EqualFold(suffix, ".ahk") ||
		   (sLen >= 5 && strings.EqualFold(s[sLen-5:], ".ahk2"))
}

func getProcessPrivilege(pid int32) string {
	handle, _, _ := procOpenProcess.Call(uintptr(0x0400), 0, uintptr(pid))
	if handle == 0 {
		return "Unknown"
	}
	defer procCloseHandle.Call(handle)

	var token syscall.Handle
	ret, _, _ := procOpenProcessToken.Call(handle, TOKEN_QUERY, uintptr(unsafe.Pointer(&token)))
	if ret == 0 {
		return "Unknown"
	}
	defer procCloseHandle.Call(uintptr(token))

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

func detectPrivilegesConcurrently(processes []ProcessInfo) {
	if len(processes) == 0 {
		return
	}

	var wg sync.WaitGroup

	maxWorkers := 4
	if len(processes) < maxWorkers {
		maxWorkers = len(processes)
	}

	type privilegeJob struct {
		index int
		pid   int32
	}

	jobChan := make(chan privilegeJob, len(processes))

	for i := 0; i < maxWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for job := range jobChan {
				processes[job.index].Privilege = getProcessPrivilege(job.pid)
			}
		}()
	}

	for i := range processes {
		jobChan <- privilegeJob{index: i, pid: processes[i].PID}
	}
	close(jobChan)

	wg.Wait()
}