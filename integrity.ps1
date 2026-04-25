# Parameter help description
param(
[Parameter(Mandatory=$true)]
[ValidateSet("Scan", "Verify")]
[string]$Mode,
[Parameter(Mandatory=$true)]
[string]$filePath,
[string]$BasePath=".\baseline.txt"
)
# Function to generate baseline hash file
function New-Baseline {
    Write-Host "Initializing baseline for $filePath..." -ForegroundColor Cyan
    if (Test-Path $BasePath) {
        Write-Host "Baseline file already exists at $BasePath. Overwriting..." -ForegroundColor Yellow
    }
    $Files =Get-ChildItem -Path $filePath -File -Recurse 
     $hashlist = foreach ($file in $Files) {
        try{
        $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        [PSCustomObject]@{
            Filename=$file.Name
            Path = $file.FullName
            SHA256 = $hash.Hash
            Size_Bytes = $file.Length
            LastWriteTime = $file.LastWriteTime
            Owner = (Get-Acl -Path $file.FullName).Owner

        }
        }
        catch{
            Write-Host "Error processing file: $($file.FullName). Skipping..." -ForegroundColor Red
        }
    }
    $hashlist | Export-Csv -Path $BasePath -NoTypeInformation
    Write-Host "Baseline created at $BasePath with $($hashlist.Count) entries" -ForegroundColor Green
}
function Compare-Hash {
    Write-Host "Comparing current file hashes to baseline..." -ForegroundColor Cyan
    if (-Not (Test-Path $BasePath)) {
        Write-Host "Baseline file not found at $BasePath. Please run in 'Scan' mode first." -ForegroundColor Red
        return
    }
    $baseline = Import-Csv -Path $BasePath
    $currentFiles = Get-ChildItem -Path $filePath -File -Recurse 
    foreach ($file in $currentFiles) {
        try{
        $currentHash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        $baselineEntry = $baseline | Where-Object { $_.Filename -eq $file.Name }
        if ($null -eq $baselineEntry) {
            Write-Host "New file detected: $($file.FullName)" -ForegroundColor Yellow
        } elseif ($currentHash.Hash -ne $baselineEntry.SHA256) {
            Write-Host "File modified: $($file.FullName)" -ForegroundColor Red
        } else {
            Write-Host "File unchanged: $($file.FullName)" -ForegroundColor Green
        }
        }
        catch{
            Write-Host "Error processing file: $($file.FullName). Skipping..." -ForegroundColor Red
        }
    }
}
switch ($Mode) {
        "Scan" { New-Baseline }
        "Verify" { Compare-Hash }
    }