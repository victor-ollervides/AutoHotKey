package main

import (
	"fmt"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

var (
	kernel32                = syscall.NewLazyDLL("kernel32.dll")
	procOpenProcess         = kernel32.NewProc("OpenProcess")
	procTerminateProcess    = kernel32.NewProc("TerminateProcess")
	procCloseHandle         = kernel32.NewProc("CloseHandle")
	procCreateToolhelp32Snapshot = kernel32.NewProc("CreateToolhelp32Snapshot")
	procProcess32First      = kernel32.NewProc("Process32FirstW")
	procProcess32Next       = kernel32.NewProc("Process32NextW")
)

const (
	PROCESS_TERMINATE = 0x0001
	TH32CS_SNAPPROCESS = 0x00000002
	MAX_PATH = 260
)

type PROCESSENTRY32 struct {
	Size              uint32
	Usage             uint32
	ProcessID         uint32
	DefaultHeapID     uintptr
	ModuleID          uint32
	Threads           uint32
	ParentProcessID   uint32
	PriorityClassBase int32
	Flags             uint32
	ExeFile           [MAX_PATH]uint16
}

// AutoHotkey process names to terminate
var ahkProcesses = []string{
	"AutoHotkey.exe",
	"AutoHotkeyU32.exe",
	"AutoHotkeyU64.exe",
	"AutoHotkey64.exe",
}

func main() {
	fmt.Println("=== AutoHotkey Process Terminator (Go) ===")
	start := time.Now()

	terminatedCount := terminateAHKProcesses()

	elapsed := time.Since(start)

	if terminatedCount > 0 {
		fmt.Printf("\n✅ Successfully terminated %d AutoHotkey process(es).\n", terminatedCount)
	} else {
		fmt.Println("⚠️  No AutoHotkey processes found running.")
	}

	fmt.Printf("Execution time: %dms\n", elapsed.Nanoseconds()/1000000)
}

func terminateAHKProcesses() int {
	processes := getRunningProcesses()
	terminatedCount := 0

	for _, proc := range processes {
		exeName := strings.ToLower(syscallUTF16ToString(proc.ExeFile[:]))

		for _, ahkProcess := range ahkProcesses {
			if strings.Contains(exeName, strings.ToLower(ahkProcess)) {
				if terminateProcess(proc.ProcessID) {
					fmt.Printf("Terminated: %s (PID: %d)\n", exeName, proc.ProcessID)
					terminatedCount++
				} else {
					fmt.Printf("Failed to terminate: %s (PID: %d)\n", exeName, proc.ProcessID)
				}
				break
			}
		}
	}

	return terminatedCount
}

func getRunningProcesses() []PROCESSENTRY32 {
	var processes []PROCESSENTRY32

	snapshot, _, _ := procCreateToolhelp32Snapshot.Call(TH32CS_SNAPPROCESS, 0)
	if snapshot == uintptr(syscall.InvalidHandle) {
		return processes
	}
	defer procCloseHandle.Call(snapshot)

	var pe32 PROCESSENTRY32
	pe32.Size = uint32(unsafe.Sizeof(pe32))

	ret, _, _ := procProcess32First.Call(snapshot, uintptr(unsafe.Pointer(&pe32)))
	if ret == 0 {
		return processes
	}

	processes = append(processes, pe32)

	for {
		ret, _, _ := procProcess32Next.Call(snapshot, uintptr(unsafe.Pointer(&pe32)))
		if ret == 0 {
			break
		}
		processes = append(processes, pe32)
	}

	return processes
}

func terminateProcess(pid uint32) bool {
	handle, _, _ := procOpenProcess.Call(PROCESS_TERMINATE, 0, uintptr(pid))
	if handle == 0 {
		return false
	}
	defer procCloseHandle.Call(handle)

	ret, _, _ := procTerminateProcess.Call(handle, 1)
	return ret != 0
}

func syscallUTF16ToString(s []uint16) string {
	for i, v := range s {
		if v == 0 {
			s = s[:i]
			break
		}
	}
	return syscall.UTF16ToString(s)
}