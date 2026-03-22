#!/usr/bin/env python3
"""
Show Running AutoHotkey Scripts with Detailed Process Information
This script provides detailed information about running AutoHotkey processes
including script filenames, process metrics, and system resources usage.

Requirements:
    pip install psutil colorama tabulate
"""

import psutil
import argparse
import sys
import os
from pathlib import Path
from colorama import init, Fore, Style
from tabulate import tabulate
import shlex

# Initialize colorama for Windows compatibility
init(autoreset=True)

def get_script_filename_from_cmdline(cmdline):
    """Extract script filename from command line arguments."""
    if not cmdline:
        return "Unknown"

    try:
        # Parse command line arguments
        if isinstance(cmdline, list):
            args = cmdline
        else:
            args = shlex.split(cmdline)

        # Look for .ahk files in command line
        for arg in args:
            if arg.endswith(('.ahk', '.ahk2')):
                return Path(arg).name

        # Fallback: look for quoted arguments that might be script files
        for i, arg in enumerate(args):
            if i > 0 and not arg.startswith('-'):
                if '\\' in arg or '/' in arg:
                    return Path(arg).name

        return "Unknown"
    except Exception:
        return "Unknown"

def get_autohotkey_processes():
    """Get all running AutoHotkey processes with detailed information."""
    processes = []

    for proc in psutil.process_iter(['pid', 'ppid', 'name', 'cmdline', 'cpu_percent', 'memory_info']):
        try:
            if proc.info['name'] and 'autohotkey' in proc.info['name'].lower():
                # Get CPU percentage (requires a brief interval)
                cpu_percent = proc.cpu_percent(interval=0.1)

                # Get memory information
                memory_info = proc.info['memory_info']
                rss_mb = memory_info.rss / (1024 * 1024)  # Physical memory in MB
                vms_mb = memory_info.vms / (1024 * 1024)  # Virtual memory in MB

                # Extract script filename
                script_file = get_script_filename_from_cmdline(proc.info['cmdline'])

                processes.append({
                    'pid': proc.info['pid'],
                    'ppid': proc.info['ppid'],
                    'name': proc.info['name'],
                    'script_file': script_file,
                    'cpu': f"{cpu_percent:.2f}",
                    'memory_mb': f"{rss_mb:.1f}",
                    'virtual_mb': f"{vms_mb:.1f}",
                    'cmdline': ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
                })
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            # Process might have ended or we don't have permission
            continue

    return processes

def format_table(processes):
    """Format process information as a table."""
    if not processes:
        return None

    headers = [
        'PID',
        'PPID',
        'Name',
        'Script File',
        'CPU %',
        'Memory (MB)',
        'Virtual (MB)'
    ]

    rows = []
    for proc in processes:
        rows.append([
            proc['pid'],
            proc['ppid'],
            proc['name'],
            proc['script_file'],
            proc['cpu'],
            proc['memory_mb'],
            proc['virtual_mb']
        ])

    return tabulate(rows, headers=headers, tablefmt='grid')

def main():
    parser = argparse.ArgumentParser(
        description='Show detailed information about running AutoHotkey processes',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
    python show_running_scripts_detailed.py
    python show_running_scripts_detailed.py --verbose
    python show_running_scripts_detailed.py --export output.txt
        """
    )

    parser.add_argument(
        '--verbose', '-v',
        action='store_true',
        help='Show verbose output including command lines'
    )

    parser.add_argument(
        '--export', '-e',
        metavar='FILE',
        help='Export results to a file'
    )

    parser.add_argument(
        '--no-color',
        action='store_true',
        help='Disable colored output'
    )

    args = parser.parse_args()

    # Disable colors if requested or if output is redirected
    use_colors = not args.no_color and sys.stdout.isatty()

    try:
        # Header
        if use_colors:
            print(f"{Fore.CYAN}AutoHotkey Running Scripts Monitor - Detailed View{Style.RESET_ALL}")
            print(f"{Fore.CYAN}======================================================{Style.RESET_ALL}")
        else:
            print("AutoHotkey Running Scripts Monitor - Detailed View")
            print("======================================================")
        print()

        # Get process information
        if use_colors:
            print(f"{Fore.YELLOW}Scanning for AutoHotkey processes...{Style.RESET_ALL}")

        processes = get_autohotkey_processes()

        if not processes:
            if use_colors:
                print(f"{Fore.YELLOW}No AutoHotkey processes are currently running.{Style.RESET_ALL}")
            else:
                print("No AutoHotkey processes are currently running.")
            return

        process_count = len(processes)
        if use_colors:
            print(f"{Fore.GREEN}Found {process_count} running AutoHotkey process(es):{Style.RESET_ALL}")
        else:
            print(f"Found {process_count} running AutoHotkey process(es):")
        print()

        # Display table
        table = format_table(processes)
        if table:
            print(table)

        # Verbose output
        if args.verbose:
            print("\nDetailed Command Lines:")
            print("=" * 50)
            for proc in processes:
                print(f"PID {proc['pid']}: {proc['cmdline']}")

        # Export to file
        if args.export:
            try:
                with open(args.export, 'w', encoding='utf-8') as f:
                    f.write("AutoHotkey Running Scripts Monitor - Detailed View\n")
                    f.write("======================================================\n\n")
                    f.write(f"Found {process_count} running AutoHotkey process(es):\n\n")
                    if table:
                        f.write(table)

                    if args.verbose:
                        f.write("\n\nDetailed Command Lines:\n")
                        f.write("=" * 50 + "\n")
                        for proc in processes:
                            f.write(f"PID {proc['pid']}: {proc['cmdline']}\n")

                if use_colors:
                    print(f"\n{Fore.GREEN}Results exported to: {args.export}{Style.RESET_ALL}")
                else:
                    print(f"\nResults exported to: {args.export}")
            except IOError as e:
                if use_colors:
                    print(f"\n{Fore.RED}Error exporting to file: {e}{Style.RESET_ALL}")
                else:
                    print(f"\nError exporting to file: {e}")

    except KeyboardInterrupt:
        if use_colors:
            print(f"\n{Fore.YELLOW}Operation cancelled by user.{Style.RESET_ALL}")
        else:
            print("\nOperation cancelled by user.")
        sys.exit(1)
    except Exception as e:
        if use_colors:
            print(f"{Fore.RED}Error: {e}{Style.RESET_ALL}")
        else:
            print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
