$ErrorActionPreference = 'Stop'

$ports = @(5012, 7012)

$listeningLines = netstat -ano -p tcp | findstr LISTENING

$pids = foreach ($p in $ports) {
  foreach ($line in $listeningLines) {
    $parts = $line.Trim() -split '\s+'
    if ($parts.Length -ge 5) {
      $local = $parts[1]
      $processId = $parts[4]
      if ($local -like "*:$p") {
        $processId
      }
    }
  }
}

$pids = $pids |
  Where-Object { $_ -match '^[0-9]+$' } |
  Sort-Object -Unique

if (-not $pids -or $pids.Count -eq 0) {
  Write-Host "No process is listening on ports $($ports -join ', ')."
  exit 0
}

foreach ($processId in $pids) {
  Write-Host "Stopping PID $processId (ports $($ports -join ', '))"
  Stop-Process -Id $processId -Force -ErrorAction SilentlyContinue
}
