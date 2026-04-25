param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Scan", "Verify")]
    [string]$Mode,

    [Parameter(Mandatory=$true)]
    [string]$filePath,

    [string]$BasePath = ".\baseline.csv" # Changed to .csv for better compatibility
)

function New-Baseline {
    Write-Host "[*] Initializing baseline for $filePath..." -ForegroundColor Cyan
    if (Test-Path $BasePath) {
        Write-Host "[!] Baseline file already exists. Overwriting..." -ForegroundColor Yellow
    }

    $Files = Get-ChildItem -Path $filePath -File -Recurse -Force -ErrorAction SilentlyContinue
    $hashlist = foreach ($file in $Files) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256 -ErrorAction Stop
            [PSCustomObject]@{
                Path          = $file.FullName
                SHA256        = $hash.Hash
                Size_Bytes    = $file.Length
                LastWriteTime = $file.LastWriteTime
                Owner         = (Get-Acl -Path $file.FullName).Owner
            }
        }
        catch {
            Write-Host "[!] Error accessing: $($file.FullName)" -ForegroundColor Red
        }
    }
    $hashlist | Export-Csv -Path $BasePath -NoTypeInformation
    Write-Host "[+] Success: Baseline created with $($hashlist.Count) entries." -ForegroundColor Green
}

function Compare-Hash {
    Write-Host "[*] Comparing live filesystem to baseline..." -ForegroundColor Cyan
    if (-Not (Test-Path $BasePath)) {
        Write-Host "[!] Error: Baseline not found. Run 'Scan' mode first." -ForegroundColor Red
        return
    }

    $baseline = Import-Csv -Path $BasePath
    $currentFiles = Get-ChildItem -Path $filePath -File -Recurse -Force -ErrorAction SilentlyContinue

    # Convert baseline to a Hash Table for much faster lookups (Efficiency!)
    $baselineLookup = @{}
    foreach ($entry in $baseline) { $baselineLookup[$entry.Path] = $entry }

    foreach ($file in $currentFiles) {
        try {
            $currentHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
            
            # Use FullPath for the lookup
            if ($null -eq $baselineLookup[$file.FullName]) {
                Write-Host "[NEW FILE] -> $($file.FullName)" -ForegroundColor Yellow
            } 
            elseif ($currentHash -ne $baselineLookup[$file.FullName].SHA256) {
                Write-Host "[MODIFIED] -> $($file.FullName)" -ForegroundColor Red
                Write-Host "    Expected: $($baselineLookup[$file.FullName].SHA256)" -ForegroundColor DarkGray
                Write-Host "    Actual:   $currentHash" -ForegroundColor DarkGray
            } 
            else {
                Write-Host "[OK] -> $($file.FullName)" -ForegroundColor Green
            }
            # Remove from lookup to track what's missing later
            $baselineLookup.Remove($file.FullName)
        }
        catch {
            Write-Host "[!] Error hashing: $($file.FullName)" -ForegroundColor Red
        }
    }

    # Anything left in the lookup was in the baseline but is now GONE
    foreach ($missing in $baselineLookup.Values) {
        Write-Host "[DELETED]  -> $($missing.Path)" -ForegroundColor Magenta
    }
}

# --- Execution Block ---
switch ($Mode) {
    "Scan"   { New-Baseline }
    "Verify" { Compare-Hash }
}