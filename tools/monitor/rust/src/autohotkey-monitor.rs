use clap::{Arg, Command};
use colored::*;
use serde::{Deserialize, Serialize};
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::process;
use sysinfo::{System, Pid};
use tabled::{Table, Tabled};

#[derive(Debug, Clone, Serialize, Deserialize, Tabled)]
struct ProcessInfo {
    #[tabled(rename = "PID")]
    pid: u32,
    #[tabled(rename = "PPID")]
    ppid: u32,
    #[tabled(rename = "Name")]
    name: String,
    #[tabled(rename = "Script File")]
    script_file: String,
    #[tabled(rename = "CPU %")]
    cpu_usage: String,
    #[tabled(rename = "Memory (MB)")]
    memory_mb: String,
    #[tabled(rename = "Virtual (MB)")]
    virtual_mb: String,
    #[tabled(skip)]
    cmdline: String,
}

#[derive(Debug)]
struct Config {
    verbose: bool,
    export: Option<String>,
    no_color: bool,
    sort_by: String,
    json: bool,
    watch: bool,
    refresh_interval: u64,
}

fn main() {
    let config = parse_args();

    if config.no_color {
        colored::control::set_override(false);
    }

    if config.watch {
        watch_mode(&config);
    } else {
        run_once(&config);
    }
}

fn parse_args() -> Config {
    let matches = Command::new("AutoHotkey Process Monitor")
        .version("1.0.0")
        .author("AutoHotkey Scripts Repository")
        .about("Monitor running AutoHotkey processes with detailed information")
        .arg(
            Arg::new("verbose")
                .short('v')
                .long("verbose")
                .help("Show verbose output including command lines")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("export")
                .short('e')
                .long("export")
                .value_name("FILE")
                .help("Export results to a file"),
        )
        .arg(
            Arg::new("no-color")
                .long("no-color")
                .help("Disable colored output")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("sort")
                .long("sort")
                .value_name("FIELD")
                .help("Sort by: pid, name, memory, cpu, script")
                .default_value("pid"),
        )
        .arg(
            Arg::new("json")
                .long("json")
                .help("Output in JSON format")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("watch")
                .short('w')
                .long("watch")
                .help("Watch mode - continuously refresh the display")
                .action(clap::ArgAction::SetTrue),
        )
        .arg(
            Arg::new("interval")
                .short('i')
                .long("interval")
                .value_name("SECONDS")
                .help("Refresh interval for watch mode (default: 2)")
                .default_value("2"),
        )
        .get_matches();

    Config {
        verbose: matches.get_flag("verbose"),
        export: matches.get_one::<String>("export").cloned(),
        no_color: matches.get_flag("no-color"),
        sort_by: matches.get_one::<String>("sort").unwrap().clone(),
        json: matches.get_flag("json"),
        watch: matches.get_flag("watch"),
        refresh_interval: matches
            .get_one::<String>("interval")
            .unwrap()
            .parse()
            .unwrap_or(2),
    }
}

fn run_once(config: &Config) {
    print_header(config);

    match get_autohotkey_processes() {
        Ok(mut processes) => {
            if processes.is_empty() {
                if !config.no_color {
                    println!("{}", "No AutoHotkey processes are currently running.".yellow());
                } else {
                    println!("No AutoHotkey processes are currently running.");
                }
                return;
            }

            sort_processes(&mut processes, &config.sort_by);

            if !config.no_color {
                println!(
                    "{}",
                    format!("Found {} running AutoHotkey process(es):", processes.len()).green()
                );
            } else {
                println!("Found {} running AutoHotkey process(es):", processes.len());
            }
            println!();

            if config.json {
                output_json(&processes);
            } else {
                output_table(&processes, config.verbose);
            }

            if let Some(export_file) = &config.export {
                if let Err(e) = export_to_file(&processes, export_file, config.verbose) {
                    if !config.no_color {
                        eprintln!("{}", format!("Error exporting to file: {}", e).red());
                    } else {
                        eprintln!("Error exporting to file: {}", e);
                    }
                } else if !config.no_color {
                    println!("{}", format!("Results exported to: {}", export_file).green());
                } else {
                    println!("Results exported to: {}", export_file);
                }
            }
        }
        Err(e) => {
            if !config.no_color {
                eprintln!("{}", format!("Error: {}", e).red());
            } else {
                eprintln!("Error: {}", e);
            }
            process::exit(1);
        }
    }
}

fn watch_mode(config: &Config) {
    loop {
        // Clear screen
        print!("\x1B[2J\x1B[1;1H");

        run_once(config);

        if !config.no_color {
            println!("{}", format!("Refreshing every {} seconds... (Ctrl+C to exit)", config.refresh_interval).blue());
        } else {
            println!("Refreshing every {} seconds... (Ctrl+C to exit)", config.refresh_interval);
        }

        std::thread::sleep(std::time::Duration::from_secs(config.refresh_interval));
    }
}

fn print_header(config: &Config) {
    if !config.no_color {
        println!("{}", "AutoHotkey Running Scripts Monitor - Detailed View".cyan());
        println!("{}", "======================================================".cyan());
    } else {
        println!("AutoHotkey Running Scripts Monitor - Detailed View");
        println!("======================================================");
    }
    println!();

    if !config.no_color {
        println!("{}", "Scanning for AutoHotkey processes...".yellow());
    }
}

fn get_autohotkey_processes() -> Result<Vec<ProcessInfo>, Box<dyn std::error::Error>> {
    let mut system = System::new_all();
    system.refresh_all();

    let mut processes = Vec::new();

    for (pid, process) in system.processes() {
        let name = process.name().to_string();

        // Check if it's an AutoHotkey process
        if !name.to_lowercase().contains("autohotkey") {
            continue;
        }

        // Extract script filename from command line
        let script_file = extract_script_filename(process.cmd());

        // Get memory usage in MB
        let memory_mb = process.memory() as f64 / 1024.0 / 1024.0;
        let virtual_mb = process.virtual_memory() as f64 / 1024.0 / 1024.0;

        // Get CPU usage
        let cpu_usage = process.cpu_usage();

        // Get parent PID
        let ppid = process.parent().unwrap_or(Pid::from(0));

        processes.push(ProcessInfo {
            pid: pid.as_u32(),
            ppid: ppid.as_u32(),
            name: name.to_string(),
            script_file,
            cpu_usage: format!("{:.2}", cpu_usage),
            memory_mb: format!("{:.1}", memory_mb),
            virtual_mb: format!("{:.1}", virtual_mb),
            cmdline: process.cmd().join(" "),
        });
    }

    Ok(processes)
}

fn extract_script_filename(cmd: &[String]) -> String {
    if cmd.is_empty() {
        return "Unknown".to_string();
    }

    // Look for .ahk or .ahk2 files in command line arguments
    for arg in cmd.iter() {
        let cleaned = arg.trim_matches('"');
        if cleaned.ends_with(".ahk") || cleaned.ends_with(".ahk2") {
            if let Some(filename) = Path::new(cleaned).file_name() {
                if let Some(name_str) = filename.to_str() {
                    return name_str.to_string();
                }
            }
        }
    }

    // Fallback: look for any file argument that might be a script
    for (i, arg) in cmd.iter().enumerate() {
        if i > 0 && !arg.starts_with('-') {
            let cleaned = arg.trim_matches('"');
            if cleaned.contains('\\') || cleaned.contains('/') {
                if let Some(filename) = Path::new(cleaned).file_name() {
                    if let Some(name_str) = filename.to_str() {
                        return name_str.to_string();
                    }
                }
            }
        }
    }

    "Unknown".to_string()
}

fn sort_processes(processes: &mut Vec<ProcessInfo>, sort_by: &str) {
    match sort_by {
        "name" => processes.sort_by(|a, b| a.name.cmp(&b.name)),
        "memory" => processes.sort_by(|a, b| {
            b.memory_mb
                .parse::<f64>()
                .unwrap_or(0.0)
                .partial_cmp(&a.memory_mb.parse::<f64>().unwrap_or(0.0))
                .unwrap_or(std::cmp::Ordering::Equal)
        }),
        "cpu" => processes.sort_by(|a, b| {
            b.cpu_usage
                .parse::<f64>()
                .unwrap_or(0.0)
                .partial_cmp(&a.cpu_usage.parse::<f64>().unwrap_or(0.0))
                .unwrap_or(std::cmp::Ordering::Equal)
        }),
        "script" => processes.sort_by(|a, b| a.script_file.cmp(&b.script_file)),
        _ => processes.sort_by(|a, b| a.pid.cmp(&b.pid)), // default: sort by PID
    }
}

fn output_table(processes: &[ProcessInfo], verbose: bool) {
    let table = Table::new(processes);
    println!("{}", table);

    if verbose {
        println!("\nDetailed Command Lines:");
        println!("{}", "=".repeat(50));
        for process in processes {
            println!("PID {}: {}", process.pid, process.cmdline);
        }
    }
}

fn output_json(processes: &[ProcessInfo]) {
    match serde_json::to_string_pretty(processes) {
        Ok(json) => println!("{}", json),
        Err(e) => eprintln!("Error serializing to JSON: {}", e),
    }
}

fn export_to_file(
    processes: &[ProcessInfo],
    filename: &str,
    verbose: bool,
) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = File::create(filename)?;

    writeln!(file, "AutoHotkey Running Scripts Monitor - Detailed View")?;
    writeln!(file, "Generated: {}", chrono::Utc::now().format("%Y-%m-%d %H:%M:%S UTC"))?;
    writeln!(file, "======================================================")?;
    writeln!(file)?;
    writeln!(file, "Found {} running AutoHotkey process(es):", processes.len())?;
    writeln!(file)?;

    let table = Table::new(processes);
    writeln!(file, "{}", table)?;

    if verbose {
        writeln!(file, "\nDetailed Command Lines:")?;
        writeln!(file, "{}", "=".repeat(50))?;
        for process in processes {
            writeln!(file, "PID {}: {}", process.pid, process.cmdline)?;
        }
    }

    Ok(())
}
