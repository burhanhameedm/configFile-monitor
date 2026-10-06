# Config File Monitor

A small PowerShell script that watches critical XML configuration files and emails an alert when one is **missing, renamed, empty, filled with NUL bytes, or no longer valid XML**.

Compatible with PowerShell 2.0 and later (Windows Server 2008 and newer).

## What it checks

| Check | Alert message |
|-------|---------------|
| File deleted, renamed, or moved | `Renamed or MISSING: <path>` |
| File is 0 bytes | `EMPTY (0 bytes): <path>` |
| File contains only NUL bytes | `ALL NULL bytes: <path>` |
| File is not well-formed XML | `INVALID XML: <path>` |

If everything is healthy, the script exits silently. When problems are found, it logs each one on its own line and sends a single HTML email listing them.

**Limitation:** it detects breakage only. A valid edit (for example, changing a value inside the XML) does not trigger an alert.

## Setup

1. Copy `Check-ConfigFiles.ps1` to a folder such as `C:\Scripts`.
2. Edit the settings at the top of the script:

   | Setting | Meaning |
   |---------|---------|
   | `$smtpServer` | SMTP server (must allow relaying from this host) |
   | `$mailTo` / `$mailFrom` | Recipient and sender addresses |
   | `$files` | Full paths of the files to monitor |
   | `$logFile` | Log file path, or `""` to disable |
   | `$requiredPath` | Optional. On clusters, set to the shared drive (e.g. `"E:\"`) so passive nodes exit quietly |

3. Test it manually:

   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Check-ConfigFiles.ps1"
   ```

   No output and no email means all files are healthy. Test with dummy files (empty, missing, or containing `<a>hello`), never production files.

## Scheduling

In Task Scheduler, choose **Create Task** and set:

- **General:** run whether user is logged on or not, with highest privileges, using an account that can read the files
- **Trigger:** daily, repeat every 10 minutes indefinitely
- **Action:** program `powershell.exe`, arguments `-NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\Check-ConfigFiles.ps1"`
- **Settings:** do not start a new instance if already running

Verify with right-click > **Run**; **Last Run Result** should show `0x0`. On clusters, deploy the script and task on every node.

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| Log entry but no email | Wrong SMTP server, or relaying not allowed |
| Healthy files reported as invalid XML | Script modified to use `Get-Content -Raw`, which PowerShell 2.0 lacks |
| Result `0x1` | Run the script manually to see the error |
| No alerts at all | `$requiredPath` points to a drive that does not exist |

## Security

Never publish real configuration files or your real email and server names. Keep placeholders in public copies.

## License

MIT. Use at your own risk and test in a non-production environment first.
