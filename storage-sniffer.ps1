# Script: storage-sniffer.ps1
# Purpose: Analyzes disk usage by scanning directories and reporting the size of each folder and file.
# Author: Beder Bourahmah
# Date: April 26th, 2025

# Define script parameters with default values
param(
    [string]$Path = ".",        # The directory to scan; defaults to the current directory
    [int]$Depth = 2,            # How many levels deep to scan; defaults to 2
    [switch]$HumanReadable,     # Optional switch to display sizes in human-readable format (KB/MB/GB)
    [switch]$Verbose            # Optional switch to enable verbose logging
)

# Function for verbose logging
function Write-VerboseLog {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    
    if ($Verbose) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

if ($Verbose) {
    Write-VerboseLog "Script started with parameters:" -ForegroundColor Cyan
    Write-VerboseLog "  Path: $Path" -ForegroundColor Cyan
    Write-VerboseLog "  Depth: $Depth" -ForegroundColor Cyan
    Write-VerboseLog "  HumanReadable: $HumanReadable" -ForegroundColor Cyan
    Write-VerboseLog "  Verbose: $Verbose" -ForegroundColor Cyan
}

# Check if the path exists
if (-not (Test-Path -Path $Path)) {
    Write-Error "The specified path does not exist: $Path"
    exit 1
}

# Check if we have access to the directory
try {
    # Try to get directory info first
    Write-VerboseLog "Attempting to get directory info for: $Path" -ForegroundColor Yellow
    $dirInfo = Get-Item -Path $Path -Force
    Write-VerboseLog "Directory info retrieved successfully" -ForegroundColor Green
    Write-VerboseLog "  IsContainer: $($dirInfo.PSIsContainer)" -ForegroundColor Yellow
    Write-VerboseLog "  Length: $($dirInfo.Length)" -ForegroundColor Yellow
    
    if (-not $dirInfo.PSIsContainer) {
        Write-Error "The specified path is not a directory: $Path"
        exit 1
    }
    
    # Try to enumerate items
    Write-VerboseLog "Attempting to enumerate items in directory" -ForegroundColor Yellow
    $testAccess = Get-ChildItem -Path $Path -Force -ErrorAction Stop
    Write-Host "Scanning directory: $Path" -ForegroundColor Green
    Write-Host "Found $($testAccess.Count) items in the directory" -ForegroundColor Green
    
    if ($Verbose) {
        Write-VerboseLog "Items found:" -ForegroundColor Yellow
        $testAccess | ForEach-Object {
            Write-VerboseLog "  $($_.Name) ($($_.GetType().Name))" -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Error "Cannot access the specified path: $Path"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Try running the script as Administrator if you need to access restricted directories." -ForegroundColor Yellow
    exit 1
}

# Function to format file size in human-readable format
function Format-FileSize {
    param([long]$Size)
    
    Write-VerboseLog "Formatting size: $Size bytes" -ForegroundColor Magenta
    $suffix = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($Size -gt 1024 -and $index -lt $suffix.Count) {
        $Size = $Size / 1024
        $index++
    }
    $result = "{0:N2} {1}" -f $Size, $suffix[$index]
    Write-VerboseLog "Formatted size: $result" -ForegroundColor Magenta
    return $result
}

# Function: Get-DirectorySize
# Purpose: Recursively calculates the size of a directory and its contents.
# Parameters:
#   - $Folder: The directory to scan
#   - $CurrentDepth: The current recursion depth (starts at 0)
#   - $MaxDepth: The maximum depth to scan (stops recursion if exceeded)
function Get-DirectorySize {
    param(
        [string]$Folder,
        [int]$CurrentDepth = 0,
        [int]$MaxDepth = 2
    )
    
    Write-VerboseLog "`nGet-DirectorySize called:" -ForegroundColor Cyan
    Write-VerboseLog "  Folder: $Folder" -ForegroundColor Cyan
    Write-VerboseLog "  CurrentDepth: $CurrentDepth" -ForegroundColor Cyan
    Write-VerboseLog "  MaxDepth: $MaxDepth" -ForegroundColor Cyan
    
    # Stop recursion if the current depth exceeds the maximum depth
    if ($CurrentDepth -gt $MaxDepth) {
        Write-VerboseLog "Max depth reached, returning 0" -ForegroundColor Yellow
        return 0L
    }

    # Get all items (files and folders) in the current directory, including hidden ones
    try {
        # First try to get the directory info
        Write-VerboseLog "Getting directory info for: $Folder" -ForegroundColor Yellow
        $dirInfo = Get-Item -Path $Folder -Force
        Write-VerboseLog "Directory info retrieved:" -ForegroundColor Green
        Write-VerboseLog "  IsContainer: $($dirInfo.PSIsContainer)" -ForegroundColor Yellow
        Write-VerboseLog "  Length: $($dirInfo.Length)" -ForegroundColor Yellow
        
        if (-not $dirInfo.PSIsContainer) {
            Write-VerboseLog "Not a container, returning length: $($dirInfo.Length)" -ForegroundColor Yellow
            return [long]$dirInfo.Length
        }

        # Then try to enumerate items
        Write-VerboseLog "Enumerating items in: $Folder" -ForegroundColor Yellow
        $items = Get-ChildItem -Path $Folder -Force -ErrorAction Stop
        Write-VerboseLog "Found $($items.Count) items" -ForegroundColor Green
        $totalSize = 0L

        # Loop through each item in the directory
        foreach ($item in $items) {
            Write-VerboseLog "`nProcessing item: $($item.FullName)" -ForegroundColor Yellow
            Write-VerboseLog "  Type: $($item.GetType().Name)" -ForegroundColor Yellow
            Write-VerboseLog "  IsContainer: $($item.PSIsContainer)" -ForegroundColor Yellow
            Write-VerboseLog "  Length: $($item.Length)" -ForegroundColor Yellow
            
            try {
                if ($item.PSIsContainer) {
                    Write-VerboseLog "  Processing as container" -ForegroundColor Yellow
                    # If the item is a folder, recursively calculate its size
                    $recursiveResult = Get-DirectorySize -Folder $item.FullName -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth
                    Write-VerboseLog "  Recursive result type: $($recursiveResult.GetType().Name)" -ForegroundColor Yellow
                    Write-VerboseLog "  Recursive result value: $recursiveResult" -ForegroundColor Yellow
                    
                    $size = [long]$recursiveResult
                    Write-VerboseLog "  Converted size: $size" -ForegroundColor Yellow
                    
                    $totalSize += $size
                    Write-VerboseLog "  New total size: $totalSize" -ForegroundColor Yellow
                } else {
                    Write-VerboseLog "  Processing as file" -ForegroundColor Yellow
                    # If the item is a file, add its size to the total
                    $totalSize += [long]$item.Length
                    Write-VerboseLog "  New total size: $totalSize" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Warning "Error processing item: $($item.FullName)"
                Write-Warning "Error details: $($_.Exception.Message)"
                if ($Verbose) {
                    Write-Warning "Error type: $($_.Exception.GetType().Name)"
                    Write-Warning "Stack trace: $($_.ScriptStackTrace)"
                }
            }
        }

        Write-VerboseLog "Returning total size: $totalSize" -ForegroundColor Green
        return $totalSize
    }
    catch {
        Write-Warning "Access denied to path: $Folder"
        Write-Warning "Error details: $($_.Exception.Message)"
        if ($Verbose) {
            Write-Warning "Error type: $($_.Exception.GetType().Name)"
            Write-Warning "Stack trace: $($_.ScriptStackTrace)"
        }
        return 0L
    }
}

# Function to get current level items with their sizes
function Get-CurrentLevelItems {
    param(
        [string]$Folder
    )
    
    $items = Get-ChildItem -Path $Folder -Force
    $results = @()
    
    foreach ($item in $items) {
        try {
            if ($item.PSIsContainer) {
                # For folders, get their total size
                $size = Get-DirectorySize -Folder $item.FullName -MaxDepth $Depth
            } else {
                # For files, use their length
                $size = [long]$item.Length
            }
            
            $results += [PSCustomObject]@{
                Path = $item.FullName
                Size = $size
            }
        }
        catch {
            Write-Warning "Error processing item: $($item.FullName)"
            Write-Warning "Error details: $($_.Exception.Message)"
        }
    }
    
    return $results
}

# Get and display current level items
$items = Get-CurrentLevelItems -Folder $Path
$totalSize = ($items | Measure-Object -Property Size -Sum).Sum

# Sort items by size in descending order and display them
$items | Sort-Object -Property Size -Descending | ForEach-Object {
    if ($HumanReadable) {
        $sizeStr = Format-FileSize $_.Size
    } else {
        $sizeStr = "$($_.Size) bytes"
    }
    Write-Host ("{0}`t{1}" -f $_.Path, $sizeStr)
}

# Output the total size
if ($HumanReadable) {
    $totalStr = Format-FileSize $totalSize
} else {
    $totalStr = "$totalSize bytes"
}
Write-Output ("Total size: {0}" -f $totalStr)

# Basic command to run the script:
# .\storage-sniffer.ps1 -Path "C:\Users\YourName" -Depth 1 -HumanReadable 