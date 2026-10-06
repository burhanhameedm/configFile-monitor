<#
.SYNOPSIS
    Monitors critical XML configuration files and emails an alert when one is
    missing, renamed, empty, filled with NUL bytes, or no longer valid XML.

.NOTES
    Compatible with PowerShell 2.0 (Windows Server 2008 / 2008 R2 and later).
    Detects BREAKAGE only. It does not detect valid content changes.
    License: MIT
#>

# ----------------------------- SETTINGS -----------------------------
# SMTP / email settings (replace with your own)
$smtpServer = "smtp.yourcompany.com"
$mailTo     = "team@yourcompany.com"
$mailFrom   = "config-monitor@yourcompany.com"

# Files to monitor (add one line per file, separate with commas)
$files = @(
    "D:\Path\To\Config\security.xml",
    "D:\Path\To\Config\server.xml"
)

# Optional: log file for every alert (set to "" to disable logging)
$logFile = "C:\Scripts\ConfigMonitor.log"

# Optional: on clustered servers, the data drive exists only on the active node.
# Set to a drive/path that must exist for the check to run (e.g. "E:\"),
# or "" to always run. If the path is missing, the script exits silently.
$requiredPath = ""
# --------------------------------------------------------------------

if ($requiredPath -ne "" -and -not (Test-Path $requiredPath)) { exit }

$problems = @()

foreach ($f in $files) {

    # 1. Missing or renamed
    if (-not (Test-Path $f)) {
        $problems += "Renamed or MISSING: $f"
        continue
    }

    # 2. Empty (0 bytes)
    if ((Get-Item $f).Length -eq 0) {
        $problems += "EMPTY (0 bytes): $f"
        continue
    }

    # 3. Filled only with NUL bytes
    $bytes   = [System.IO.File]::ReadAllBytes($f)
    $nonNull = $bytes | Where-Object { $_ -ne 0 } | Select-Object -First 1
    if ($nonNull -eq $null) {
        $problems += "ALL NULL bytes: $f"
        continue
    }

    # 4. Not valid XML (truncated, damaged, or edited incorrectly)
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($f)
    } catch {
        $problems += "INVALID XML: $f"
    }
}

if ($problems.Count -gt 0) {

    # Log: one problem per line
    if ($logFile -ne "") {
        foreach ($p in $problems) {
            Add-Content $logFile ("{0}  {1}" -f (Get-Date), $p)
        }
    }

    # Email (HTML list so each problem is on its own line in every mail client)
    $items = ($problems | ForEach-Object {
        "<li>" + [System.Security.SecurityElement]::Escape($_) + "</li>"
    }) -join ""

    $body = "<html><body><p>Problems found on <b>$env:COMPUTERNAME</b> at $(Get-Date):</p><ul>$items</ul></body></html>"

    Send-MailMessage -To $mailTo -From $mailFrom -SmtpServer $smtpServer `
        -Subject "ALERT: Config file problem on $env:COMPUTERNAME" `
        -Body $body -BodyAsHtml
}
