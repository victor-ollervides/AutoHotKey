#include <windows.h>
#include <iostream>
#include <vector>
#include <string>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <algorithm>
#include <chrono>

class ElevatedStartupLauncher {
private:
    std::wstring scriptsPath;
    std::wstring ahkV1Path;
    std::wstring ahkV2Path;
    std::vector<std::wstring> logBuffer;

    void findAutoHotkeyExecutables() {
        // AutoHotkey v1 paths (in order of preference)
        std::vector<std::wstring> v1Paths = {
            L"C:\\Program Files\\AutoHotkey\\AutoHotkeyU64.exe",
            L"C:\\Program Files\\AutoHotkey\\AutoHotkeyU32.exe",
            L"C:\\Program Files\\AutoHotkey\\AutoHotkey.exe"
        };

        // AutoHotkey v2 paths
        std::vector<std::wstring> v2Paths = {
            L"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey.exe",
            L"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey64.exe",
            L"C:\\Program Files\\AutoHotkey\\v2\\AutoHotkey32.exe"
        };

        // Find v1 executable
        for (const auto& path : v1Paths) {
            if (std::filesystem::exists(path)) {
                ahkV1Path = path;
                break;
            }
        }

        // Find v2 executable
        for (const auto& path : v2Paths) {
            if (std::filesystem::exists(path)) {
                ahkV2Path = path;
                break;
            }
        }
    }

    bool isAutoHotkeyV2Script(const std::wstring& scriptPath) {
        std::wifstream file(scriptPath);
        if (!file.is_open()) {
            return false; // Default to v1 if can't read
        }

        std::wstring line;
        int lineCount = 0;

        // Check first 20 lines for v2 indicators
        while (std::getline(file, line) && lineCount < 20) {
            // Convert to lowercase for comparison
            std::wstring lowerLine = line;
            std::transform(lowerLine.begin(), lowerLine.end(), lowerLine.begin(), ::towlower);

            // V2 indicators
            if (lowerLine.find(L"#requires autohotkey v2") != std::wstring::npos ||
                lowerLine.find(L"#requires v2") != std::wstring::npos) {
                return true;
            }

            // V1 indicators (strong indicators it's NOT v2)
            if (lowerLine.find(L"#noenv") != std::wstring::npos ||
                lowerLine.find(L"sendmode, input") != std::wstring::npos ||
                lowerLine.find(L"setbatchlines") != std::wstring::npos ||
                lowerLine.find(L"#singleinstance, force") != std::wstring::npos) {
                return false;
            }

            lineCount++;
        }

        // Check file extension
        if (scriptPath.ends_with(L".ahk2")) {
            return true;
        }

        // Default to v1 for .ahk files without clear v2 indicators
        return false;
    }

    bool launchScript(const std::wstring& scriptPath) {
        // Determine which AutoHotkey version to use
        bool useV2 = isAutoHotkeyV2Script(scriptPath);
        std::wstring ahkPath = useV2 ? ahkV2Path : ahkV1Path;

        if (ahkPath.empty()) {
            logMessage(L"ERROR: AutoHotkey " + std::wstring(useV2 ? L"v2" : L"v1") + L" executable not found");
            return false;
        }

        // Show which script is being launched
        std::wstring scriptName = std::filesystem::path(scriptPath).filename().wstring();
        logMessage(L"Launching: " + scriptName);

        std::wstring commandLine = L"\"" + ahkPath + L"\" \"" + scriptPath + L"\"";

        STARTUPINFOW si = {};
        si.cb = sizeof(STARTUPINFOW);
        si.dwFlags = STARTF_USESHOWWINDOW;
        si.wShowWindow = SW_HIDE;

        PROCESS_INFORMATION pi = {};

        BOOL result = CreateProcessW(
            nullptr,
            const_cast<LPWSTR>(commandLine.c_str()),
            nullptr,
            nullptr,
            FALSE,
            CREATE_NEW_CONSOLE,
            nullptr,
            nullptr,
            &si,
            &pi
        );

        if (result) {
            CloseHandle(pi.hProcess);
            CloseHandle(pi.hThread);
            return true;
        } else {
            DWORD error = GetLastError();
            logMessage(L"[FAIL] Failed to launch (Error: " + std::to_wstring(error) + L")");
        }

        return false;
    }

    void logMessage(const std::wstring& message) {
        // Convert to regular string
        int size = WideCharToMultiByte(CP_ACP, 0, message.c_str(), -1, nullptr, 0, nullptr, nullptr);
        std::string consoleMessage(size - 1, 0);
        WideCharToMultiByte(CP_ACP, 0, message.c_str(), -1, &consoleMessage[0], size, nullptr, nullptr);

        // Display to console
        std::cout << consoleMessage << std::endl;
        std::cout.flush();

        // Also log to file
        std::string trimmed = consoleMessage;
        trimmed.erase(0, trimmed.find_first_not_of(" \t\r\n"));
        if (!trimmed.empty() && trimmed.find_last_not_of(" \t\r\n") != std::string::npos) {
            trimmed.erase(trimmed.find_last_not_of(" \t\r\n") + 1);
        }

        if (!trimmed.empty()) {
            SYSTEMTIME st;
            GetLocalTime(&st);

            std::string logEntry = "[" + std::to_string(st.wYear) + "-" +
                                  std::to_string(st.wMonth) + "-" +
                                  std::to_string(st.wDay) + " " +
                                  std::to_string(st.wHour) + ":" +
                                  std::to_string(st.wMinute) + ":" +
                                  std::to_string(st.wSecond) + "] " +
                                  trimmed;

            logBuffer.push_back(std::wstring(logEntry.begin(), logEntry.end()));
        }
    }

    void writeLogBuffer() {
        if (!logBuffer.empty()) {
            std::wofstream logFileHandle(L"startup-launcher.log", std::ios::app);
            if (logFileHandle.is_open()) {
                for (const auto& entry : logBuffer) {
                    logFileHandle << entry << L"\n";
                }
                logFileHandle.close();
                logBuffer.clear();
            }
        }
    }

public:
    ElevatedStartupLauncher(const std::wstring& scriptsDirectory)
        : scriptsPath(scriptsDirectory) {}

    int run() {
        auto startTime = std::chrono::high_resolution_clock::now();

        logMessage(L"=== AutoHotkey Startup Launcher (C++) ===");
        logMessage(L"Starting elevated AutoHotkey launcher...");
        logMessage(L"");

        findAutoHotkeyExecutables();

        if (ahkV1Path.empty() && ahkV2Path.empty()) {
            logMessage(L"ERROR: No AutoHotkey executables found");
            logMessage(L"Please install AutoHotkey v1 or v2");
            return 1;
        }

        logMessage(L"AutoHotkey installations found:");
        if (!ahkV1Path.empty()) {
            logMessage(L"  - v1: " + ahkV1Path);
        }
        if (!ahkV2Path.empty()) {
            logMessage(L"  - v2: " + ahkV2Path);
        }
        logMessage(L"");

        if (!std::filesystem::exists(scriptsPath)) {
            logMessage(L"ERROR: Scripts directory not found: " + scriptsPath);
            return 1;
        }

        logMessage(L"Scanning scripts directory: " + scriptsPath);
        logMessage(L"");

        int launchedCount = 0;

        try {
            for (const auto& entry : std::filesystem::directory_iterator(scriptsPath)) {
                if (entry.is_regular_file()) {
                    std::wstring filename = entry.path().filename().wstring();
                    std::wstring extension = entry.path().extension().wstring();

                    if (extension == L".ahk" || extension == L".ahk2") {
                        std::wstring fullPath = entry.path().wstring();

                        if (launchScript(fullPath)) {
                            launchedCount++;
                            // Removed delay for better performance
                        }
                    }
                }
            }
        } catch (const std::exception& e) {
            logMessage(L"ERROR: Exception occurred while scanning directory");
            return 1;
        }

        logMessage(L"");
        if (launchedCount > 0) {
            logMessage(L"[OK] Launcher completed successfully!");
            logMessage(L"Total scripts launched: " + std::to_wstring(launchedCount));
        } else {
            logMessage(L"[WARNING] No scripts were found to launch");
            logMessage(L"Make sure .ahk or .ahk2 files exist in: " + scriptsPath);
        }

        auto endTime = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(endTime - startTime);

        logMessage(L"");
        logMessage(L"Execution time: " + std::to_wstring(duration.count()) + L"ms");
        logMessage(L"Press any key to exit...");

        writeLogBuffer();
        std::cin.get();

        return 0;
    }
};

int wmain(int argc, wchar_t* argv[]) {
    std::wstring scriptsPath = L"scripts\\startup";

    // Parse command line arguments
    for (int i = 1; i < argc; i++) {
        std::wstring arg = argv[i];
        if (arg == L"--path" && i + 1 < argc) {
            scriptsPath = argv[i + 1];
            i++;
        } else if (arg == L"--help") {
            std::cout << "=== AutoHotkey Startup Launcher (Optimized) ===" << std::endl;
            std::cout << "Launches AutoHotkey scripts from a specified directory" << std::endl;
            std::cout << std::endl;
            std::cout << "Usage: startup-launcher.exe [--path <scripts_directory>]" << std::endl;
            std::cout << std::endl;
            std::cout << "Options:" << std::endl;
            std::cout << "  --path <dir>    Specify scripts directory (default: scripts\\startup)" << std::endl;
            std::cout << "  --help          Show this help message" << std::endl;
            std::cout << std::endl;
            std::cout << "Supported file types: .ahk (AutoHotkey v1), .ahk2 (AutoHotkey v2)" << std::endl;
            std::cout << "Optimizations: Execution timing, removed delays" << std::endl;
            return 0;
        }
    }

    ElevatedStartupLauncher launcher(scriptsPath);
    return launcher.run();
}