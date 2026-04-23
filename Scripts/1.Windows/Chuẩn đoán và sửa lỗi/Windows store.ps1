# ==============================================================================
# CÔNG CỤ TỰ ĐỘNG PHỤC HỒI MICROSOFT STORE & APP INSTALLER (WINGET)
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Yêu cầu quyền Admin
$TaiKhoan = [Security.Principal.WindowsIdentity]::GetCurrent()
$QuyenAdmin = [Security.Principal.WindowsPrincipal]$TaiKhoan
if (-not $QuyenAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Form chinh ───────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Phuc Hoi He Sinh Thai Microsoft"
$form.Size            = New-Object System.Drawing.Size(520, 340)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)

# ── Tieu de ──────────────────────────────────────────────────────────────────
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "PHUC HOI HE SINH THAI MICROSOFT"
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location  = New-Object System.Drawing.Point(20, 18)
$lblTitle.Size      = New-Object System.Drawing.Size(470, 30)
$form.Controls.Add($lblTitle)

# ── Duong ke ngang ───────────────────────────────────────────────────────────
$sep = New-Object System.Windows.Forms.Label
$sep.BorderStyle = "Fixed3D"
$sep.Location    = New-Object System.Drawing.Point(20, 55)
$sep.Size        = New-Object System.Drawing.Size(470, 2)
$form.Controls.Add($sep)

# ── Noi dung mo ta ───────────────────────────────────────────────────────────
$lines = @(
    "Cong cu nay se giup ban:",
    "   1. Khoi phuc va dang ky lai Microsoft Store.",
    "   2. Cai dat thu vien nen tang VCLibs & UI.Xaml.",
    "   3. Cai dat App Installer (Trinh quan ly goi Winget)."
)
$y = 68
foreach ($line in $lines) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $line
    $lbl.ForeColor = if ($line -match "^Cong") {
        [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    } else {
        [System.Drawing.ColorTranslator]::FromHtml("#E2E8F0")
    }
    $lbl.Location  = New-Object System.Drawing.Point(20, $y)
    $lbl.Size      = New-Object System.Drawing.Size(470, 22)
    $form.Controls.Add($lbl)
    $y += 24
}

# ── Label trang thai ─────────────────────────────────────────────────────────
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Trang thai: Dang cho lenh..."
$lblStatus.ForeColor = [System.Drawing.ColorTranslator]::FromHtml("#38BDF8")
$lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblStatus.Location  = New-Object System.Drawing.Point(20, 178)
$lblStatus.Size      = New-Object System.Drawing.Size(470, 22)
$form.Controls.Add($lblStatus)

# ── Progress bar ─────────────────────────────────────────────────────────────
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Minimum  = 0
$progress.Maximum  = 100
$progress.Value    = 0
$progress.Style    = "Continuous"
$progress.Location = New-Object System.Drawing.Point(20, 205)
$progress.Size     = New-Object System.Drawing.Size(470, 18)
$form.Controls.Add($progress)

# ── Nut bat dau ──────────────────────────────────────────────────────────────
$btn = New-Object System.Windows.Forms.Button
$btn.Text      = "BAT DAU PHUC HOI"
$btn.ForeColor = [System.Drawing.Color]::White
$btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3B82F6")
$btn.FlatStyle = "Flat"
$btn.FlatAppearance.BorderSize = 0
$btn.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btn.Location  = New-Object System.Drawing.Point(20, 238)
$btn.Size      = New-Object System.Drawing.Size(470, 48)
$btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btn)

# ── Bien chia se thread-safe ─────────────────────────────────────────────────
$shared = [hashtable]::Synchronized(@{
    Status   = ""
    Progress = -1
    Done     = $false
    HasError = $false
})

# ── Script chay nen ──────────────────────────────────────────────────────────
$workerScript = {
    param($shared)

    function SetUI($msg, $pct) {
        if ($null -ne $msg) { $shared.Status   = $msg }
        if ($null -ne $pct) { $shared.Progress = $pct }
    }

    function Install($url, $file, $mode) {
        $path = Join-Path $env:TEMP $file
        try {
            if ($mode -eq "web") {
                Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing -EA SilentlyContinue
            } else {
                $req    = [System.Net.HttpWebRequest]::Create($url)
                $resp   = $req.GetResponse()
                $stream = $resp.GetResponseStream()
                $fs     = [System.IO.FileStream]::new($path, [System.IO.FileMode]::Create)
                $buf    = New-Object byte[] 65536
                do { $n = $stream.Read($buf,0,$buf.Length); if($n -gt 0){$fs.Write($buf,0,$n)} } while ($n -gt 0)
                $fs.Close(); $stream.Close(); $resp.Close()
            }
            if (Test-Path $path) {
                Add-AppxPackage -Path $path -EA SilentlyContinue
                Remove-Item $path -Force -EA SilentlyContinue
            }
        } catch {}
    }

    try {
        SetUI "Dang xoa bo nho dem Microsoft Store (wsreset)..." 10
        Start-Process "wsreset.exe" -ArgumentList "-i" -WindowStyle Hidden -Wait -EA SilentlyContinue

        SetUI "Dang dang ky lai nhan ung dung Store..." 25
        Get-AppxPackage -allusers Microsoft.WindowsStore -EA SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -EA SilentlyContinue
        }

        SetUI "Dang tai thu vien nen tang VCLibs (x64)..." 40
        Install "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" "VCLibs.appx" "web"

        SetUI "Dang tai giao dien he thong UI.Xaml 2.8..." 55
        Install "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" "UIXaml.appx" "web"

        SetUI "Dang tai trinh quan ly goi App Installer (Winget)..." 70
        Install "https://aka.ms/getwinget" "AppInstaller.msixbundle" "stream"

        SetUI "Dang cau hinh he thong..." 90
        Start-Sleep -Seconds 2

        SetUI "Hoan tat! He sinh thai Microsoft da duoc phuc hoi." 100
        $shared.Done = $true
    } catch {
        SetUI "Co loi xay ra: $_" 0
        $shared.HasError = $true
        $shared.Done     = $true
    }
}

# ── Timer poll UI ─────────────────────────────────────────────────────────────
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 400

$script:timerHandler = $null
$script:timerHandler = {
    if ($shared.Status -ne "") {
        $lblStatus.Text = "Trang thai: " + $shared.Status
        $shared.Status  = ""
    }
    if ($shared.Progress -ge 0) {
        $progress.Value  = [Math]::Min($shared.Progress, 100)
        $shared.Progress = -1
    }
    if ($shared.Done) {
        $timer.Stop()
        $timer.Remove_Tick($script:timerHandler)
        try { $script:ps.Dispose(); $script:rs.Close(); $script:rs.Dispose() } catch {}

        $progress.Value = 100

        if ($shared.HasError) {
            $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#EF4444")
            $btn.Text      = "LOI - BAM DE THOAT"
        } else {
            $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
            $btn.Text      = "HOAN TAT - BAM DE THOAT"
        }

        # Xoa het handler cu, gan handler thoat
        $btn.remove_Click($script:btnHandler)
        $btn.Add_Click({ $form.Close() })
        $btn.Enabled = $true
    }
}
$timer.Add_Tick($script:timerHandler)

# ── Handler nut bat dau ───────────────────────────────────────────────────────
$script:btnHandler = {
    $btn.Enabled   = $false
    $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#475569")
    $btn.Text      = "DANG XU LY..."

    $script:rs = [runspacefactory]::CreateRunspace()
    $script:rs.Open()

    $script:ps = [powershell]::Create()
    $script:ps.Runspace = $script:rs
    [void]$script:ps.AddScript($workerScript).AddArgument($shared)
    [void]$script:ps.BeginInvoke()

    $timer.Start()
}
$btn.Add_Click($script:btnHandler)

# ── Chay form ────────────────────────────────────────────────────────────────
[void]$form.ShowDialog()