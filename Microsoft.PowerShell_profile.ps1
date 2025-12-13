# Disable Python venv prompt change (handled by Oh My Posh)
$env:VIRTUAL_ENV_DISABLE_PROMPT = 1

# 1. PRE-CHECKS & CONFIGURATION
# -----------------------------------------------------------------------------
Set-StrictMode -Version Latest
$Global:Editor = if (Get-Command "code" -ErrorAction SilentlyContinue) { "code" } else { "notepad" }

# 2. HELPER FUNCTIONS (SAFETY & UTILITY)
# -----------------------------------------------------------------------------

# Helper: Import modules safely without errors
function Import-SafeModule {
    param([string]$ModuleName)
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Import-Module -Name $ModuleName
    }
}

# Helper: Run tool only if installed, otherwise show a hint
function Run-IfAvailable {
    param(
        [string]$ToolName,
        [scriptblock]$Command,
        [string]$InstallHint
    )
    if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
        & $Command
    } else {
        # Silent failure preferred for cleaner startup
    }
}

# 3. INITIALIZATION (MODULES & THEMES)
# -----------------------------------------------------------------------------
Import-SafeModule "Terminal-Icons"

# Dynamic Shell Detection (Fix for pwsh vs powershell)
$ShellType = if ($PSVersionTable.PSVersion.Major -ge 6) { "pwsh" } else { "powershell" }

# Initialize Oh My Posh
Run-IfAvailable -ToolName "oh-my-posh" -Command {
    oh-my-posh init $ShellType --config "~/.poshthemes/hotanphat.omp.json" | Invoke-Expression
} -InstallHint "winget install JanDeDobbeleer.OhMyPosh"

# Initialize Zoxide
Run-IfAvailable -ToolName "zoxide" -Command {
    Invoke-Expression (& { (zoxide init --cmd z powershell | Out-String) })
} -InstallHint "winget install ajeetdsouza.zoxide"

# 4. PSREADLINE CONFIGURATION (UX & COLORS)
# -----------------------------------------------------------------------------
Import-SafeModule "PSReadLine"
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -HistoryNoDuplicates

# Brand-aligned Color Palette
$BrandColors = @{
    "Command"    = "#FFC90E" # Golden
    "Parameter"  = "#D6D6D6" # Light Gray
    "Operator"   = "#0EFFC9" # Cyan
    "Variable"   = "#C90EFF" # Purple
    "String"     = "#F4F4F4" # Light (White-ish)
    "Comment"    = "#646464" # Dark Gray
}
Set-PSReadLineOption -Colors $BrandColors

# 5. CORE FUNCTIONS
# -----------------------------------------------------------------------------
function Edit-Profile { & $Global:Editor $PROFILE }

function Reload-Profile {
    & $PROFILE
    Write-Host " [] Profile Reloaded" -ForegroundColor Cyan
}

# Admin Mode: Run command in new elevated Windows Terminal tab
function sudo {
    param([string]$Command)
    if (-not $Command) {
        Start-Process wt -Verb RunAs
        return
    }
    # Note: Complex quoting in $Command may fail. Use simple strings.
    Start-Process wt -Verb RunAs -ArgumentList "new-tab -p `"PowerShell`" -- pwsh -NoExit -Command `"$Command`""
}

function grep {
    param($Pattern)
    $Input | Select-String -Pattern $Pattern
}

# 6. HELP FUNCTION
# -----------------------------------------------------------------------------
function Show-Help {
    Clear-Host
    Write-Host ":: Terminal Help ::" -ForegroundColor Yellow
    Write-Host "=======================" -ForegroundColor DarkGray
    Write-Host ""

    # Helper for formatting: Cyan Command | White Description
    $Format = "  {0,-15} {1}"
    
    Write-Host " [ CORE ]" -ForegroundColor Magenta
    Write-Host ($Format -f "Edit-Profile", "Open profile in editor")
    Write-Host ($Format -f "Reload-Profile", "Reload profile changes")
    Write-Host ($Format -f "sudo", "Run as Administrator (New Tab)")
    Write-Host ($Format -f "sysinfo", "Get System Info")
    Write-Host ""

    Write-Host " [ GIT WORKFLOW ]" -ForegroundColor Magenta
    Write-Host ($Format -f "gs", "Status")
    Write-Host ($Format -f "ga", "Add All (.)")
    Write-Host ($Format -f "gc 'msg'", "Commit")
    Write-Host ($Format -f "gp / gpl", "Push / Pull")
    Write-Host ($Format -f "gnew 'name'", "New Branch (Checkout -b)")
    Write-Host ($Format -f "gcheckout", "Checkout Branch")
    Write-Host ($Format -f "gmerge", "Merge Branch")
	Write-Host ($Format -f "lazyg 'msg'", "Add, Commit and Push")
    Write-Host ""

    Write-Host " [ FILES & NAV ]" -ForegroundColor Magenta
    Write-Host ($Format -f "ls / ll", "Smart List (lsd/eza)")
    Write-Host ($Format -f "z", "Smart Jump (zoxide)")
    Write-Host ($Format -f ".. / ...", "Go up 1 or 2 levels")
    Write-Host ($Format -f "grep", "Select-String pattern")
    Write-Host ""

    Write-Host " [ WSL ]" -ForegroundColor Magenta
    Write-Host ($Format -f "wsll", "List Local (Verbose)")
    Write-Host ($Format -f "wsllo", "List Online")
    Write-Host ""
}

# 7. ALIASES & SHORTCUTS
# -----------------------------------------------------------------------------
# Navigation
Set-Alias -Name ".." -Value "cd .."
Set-Alias -Name "..." -Value "cd ../.."

# Smart Listing (lsd -> eza -> standard)
function ls {
    if (Get-Command "lsd" -ErrorAction SilentlyContinue) {
        lsd --group-dirs first $args
    } elseif (Get-Command "eza" -ErrorAction SilentlyContinue) {
        eza --icons --group-directories-first $args
    } else {
        Get-ChildItem -Force $args
    }
}

function ll {
    if (Get-Command "lsd" -ErrorAction SilentlyContinue) {
        lsd -la --group-dirs first $args
    } elseif (Get-Command "eza" -ErrorAction SilentlyContinue) {
        eza -la --icons --group-directories-first $args
    } else {
        Get-ChildItem -Force -Verbose $args
    }
}

# Git Workflow
function gs { git status }
function ga { git add . }
function gc { param($m) git commit -m "$m" }
function gp { git push }
function gpl { git pull }
function gfetch { git fetch }
function gbranch { git branch }
function gdelete { param($b) git branch -d $b }
function gcheckout { param($b) git checkout $b }
function gmerge { param($b) git merge $b }
function lazyg {
	git add .
	param($m) git commit -m "$m"
	git push
}

# Create new branch: gnew <name> [base]
function gnew { 
    param($Name, $Base)
    if ($Base) { git checkout -b $Name $Base } else { git checkout -b $Name }
}

# WSL Utilities
function wsll { wsl --list --verbose }
function wsllo { wsl --list --online }

# System
Set-Alias -Name "sysinfo" -Value "Get-ComputerInfo"
Set-Alias -Name "which" -Value "Get-Command"

# 8. WELCOME
# -----------------------------------------------------------------------------
Clear-Host
Write-Host ":::: Greeting Master, System is ready ::::" -ForegroundColor DarkGray
Write-Host ":::: Type 'Show-Help' for commands    ::::" -ForegroundColor DarkGray
