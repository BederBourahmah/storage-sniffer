# storage-sniffer

A PowerShell script to analyze disk usage and find which folders and files are using the most space.

## Usage

Basic usage:
```powershell
.\storage-sniffer.ps1 -Path "C:\Users\YourName" -Depth 3 -HumanReadable
```

With verbose logging for troubleshooting:
```powershell
.\storage-sniffer.ps1 -Path "C:\Users\YourName" -Depth 3 -HumanReadable -Verbose
```

## Parameters

- `-Path`: Directory to scan (default: current directory)
- `-Depth`: How many levels deep to scan (default: 2)
- `-HumanReadable`: Show sizes in KB/MB/GB instead of bytes
- `-Verbose`: Enable detailed logging for troubleshooting

## Examples

Scan current directory with default settings:
```powershell
.\storage-sniffer.ps1
```

Scan a specific directory with human-readable sizes:
```powershell
.\storage-sniffer.ps1 -Path "C:\Program Files" -HumanReadable
```

Deep scan with verbose logging:
```powershell
.\storage-sniffer.ps1 -Path "C:\Users" -Depth 4 -HumanReadable -Verbose
```

## Output

The script analyzes the specified directory and displays:
- All items (files and folders) at the current level
- Items are sorted by size in descending order (largest first)
- For folders, shows their total size including all contents
- For files, shows their direct size
- Total size of all items at the current level

Example output:
```
Scanning directory: .
Found 4 items in the directory
C:\repos\storage-sniffer\.git   24860 bytes
C:\repos\storage-sniffer\storage-sniffer.ps1    9673 bytes
C:\repos\storage-sniffer\README.md      1835 bytes
C:\repos\storage-sniffer\.gitignore     82 bytes
Total size: 36450 bytes
```

When using `-Verbose`, additional diagnostic information is displayed to help troubleshoot any issues. 