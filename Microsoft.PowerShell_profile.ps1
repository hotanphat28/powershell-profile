# Disable Python venv prompt change (handled by Oh My Posh)
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

# 1. PRE-CHECKS & CONFIGURATION
# ::::
Set-StrictMode -Version Latest

# Define preferred editors in order (matches Chris Titus list)
$Editors = @("nvim", "pvim", "vim", "vi", "code", "codium", "notepad++", "sublime_text", "notepad")

# Select the first available editor from the list
$Global:Editor = $Editors | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1

# 2. HELPER FUNCTIONS
# ::::

function Import-SafeModule {
    param([string]$ModuleName)
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Import-Module -Name $ModuleName
    }
}

function Run-IfAvailable {
    param([string]$ToolName, [scriptblock]$Command)
    if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
        & $Command
    }
}

# 3. INITIALIZATION
# ::::
Import-SafeModule "Terminal-Icons"

# Dynamic Shell Detection
$ShellType = if ($PSVersionTable.PSVersion.Major -ge 6) { "pwsh" } else { "powershell" }

# Initialize Oh My Posh
Run-IfAvailable -ToolName "oh-my-posh" -Command {
    oh-my-posh init $ShellType --config "~/.poshthemes/hotanphat2.omp.json" | Invoke-Expression
}

# Initialize Zoxide
Run-IfAvailable -ToolName "zoxide" -Command {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
}

# 4. PSREADLINE CONFIGURATION
# ::::
Import-SafeModule "PSReadLine"
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistoryNoDuplicates

$BrandColors = @{
    "Command"    = "#FFC90E"
    "Parameter"  = "#D6D6D6"
    "Operator"   = "#0EFFC9"
    "Variable"   = "#C90EFF"
    "String"     = "#F4F4F4"
    "Comment"    = "#646464"
}
Set-PSReadLineOption -Colors $BrandColors

# 5. CORE FUNCTIONS
# ::::
function Edit-Profile { & $Global:Editor $PROFILE }

function Reload-Profile {
    & $PROFILE
    Write-Host "[✓] Profile Reloaded" -ForegroundColor Cyan
    Write-Host ""
}

# Linux 'sudo' behavior using Windows Terminal Elevation
function sudo {
    if (-not $args) {
        Start-Process wt -Verb RunAs
        return
    }
    Start-Process wt -Verb RunAs -ArgumentList "new-tab -p `"PowerShell`" -- pwsh -NoExit -Command `"$args`""
}

# Linux 'grep' behavior using Windows Select-String
function grep {
    $Input | Select-String -Pattern $args
}

# Linux 'touch' behavior using Windows New-Item
function touch {
    if (-not (Test-Path $args)) {
        New-Item -ItemType File -Path $args | Out-Null
    } else {
        (Get-Item $args).LastWriteTime = Get-Date
    }
}

# Linux 'df' behavior using Windows Get-Volume
function df {
    Get-Volume
}

# 6. ALIASES & SHORTCUTS
# ::::
# Navigation
Set-Alias -Name ".." -Value "cd .."
Set-Alias -Name "..." -Value "cd ../.."

# Native Windows Listing
# 'ls' is already an alias for Get-ChildItem in PowerShell
# 'll' shows hidden files and details (like ls -la)
function ll {
    Get-ChildItem -Force | Format-Table -AutoSize
}

# Git Workflow
# Note: $args allows you to type messages without quotes (e.g., gc my update)
function gstatus { git status }
function gadd { git add . }
function gcommit { git commit -m "$args" }
function gpush { git push }
function gpull { git pull }
function gfetch { git fetch }
function gbranch { git branch }
function gdelete { git branch -d $args }
function gcheckout { git checkout $args }
function gmerge { git merge $args }

function lazyg {
    git add .
    git commit -m "$args"
    git push
}

function gnew { 
    # Usage: gnew <name> OR gnew <name> <base_branch>
    if ($args[1]) { 
        git checkout -b $args[0] $args[1] 
    } else { 
        git checkout -b $args[0] 
    }
}

# WSL Utilities
function wsll { wsl --list --verbose }
function wsllo { wsl --list --online }

# System
Set-Alias -Name "sysinfo" -Value "Get-ComputerInfo"
Set-Alias -Name "which" -Value "Get-Command"
Set-Alias -Name "open" -Value "Invoke-Item"

# 7. HELP FUNCTION
# ::::
function Show-Help {
    Clear-Host
    Write-Host ":::::::::::::::::::::::" -ForegroundColor DarkGray
    Write-Host ":::: Terminal Help ::::" -ForegroundColor Yellow
    Write-Host ":::::::::::::::::::::::" -ForegroundColor DarkGray
    Write-Host ""

    $Format = "  {0,-15} {1}"
    
    Write-Host " [ SYSTEM ]" -ForegroundColor Magenta
    Write-Host ($Format -f "sudo", "Run as Admin (New Tab)")
    Write-Host ($Format -f "Edit-Profile", "Edit Profile")
    Write-Host ($Format -f "Reload-Profile", "Reload changes")
    Write-Host ($Format -f "open", "Open file (Invoke-Item)")
    Write-Host ""

    Write-Host " [ LINUX STYLE ]" -ForegroundColor Magenta
    Write-Host ($Format -f "grep", "Select-String")
    Write-Host ($Format -f "touch", "New-Item (File)")
    Write-Host ($Format -f "df", "Get-Volume")
    Write-Host ($Format -f "ll", "Get-ChildItem -Force")
    Write-Host ($Format -f "z", "Smart Jump (Zoxide)")
    Write-Host ""

    Write-Host " [ GIT WORKFLOW ]" -ForegroundColor Magenta
    Write-Host ($Format -f "gstatus / gadd", "Status / Add All")
    Write-Host ($Format -f "gcommit [msg]", "Commit")
    Write-Host ($Format -f "lazyg [msg]", "Add + Commit + Push")
    Write-Host ($Format -f "gnew [name]", "New Branch")
    Write-Host ""
}

# 8. WELCOME
# ::::
Clear-Host
Write-Host "::::●○::::" -ForegroundColor Yellow
Write-Host ":::●○●::::" -ForegroundColor Yellow
Write-Host "::●●○●::::" -ForegroundColor Yellow
Write-Host ":●●●○○::::" -ForegroundColor Yellow
Write-Host ""
Write-Host ":::: Greeting Master, System is ready ::::" -ForegroundColor DarkGray
Write-Host ""
Write-Host ":::: Type 'Show-Help' for commands    ::::" -ForegroundColor DarkGray
Write-Host ""
