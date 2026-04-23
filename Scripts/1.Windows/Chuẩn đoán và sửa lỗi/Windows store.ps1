# ==============================================================================
# CÔNG CỤ TỰ ĐỘNG PHỤC HỒI MICROSOFT STORE & APP INSTALLER (WINGET)
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$TaiKhoan   = [Security.Principal.WindowsIdentity]::GetCurrent()
$QuyenAdmin = [Security.Principal.WindowsPrincipal]$TaiKhoan
if (-not $QuyenAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}
Set-ExecutionPolicy Bypass -Scope Process -Force

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# ── Form chính ───────────────────────────────────────────────────────────────
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Phục Hồi Hệ Sinh Thái Microsoft"
$form.Size            = New-Object System.Drawing.Size(520, 340)
$form.StartPosition   = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox     = $false
$form.MinimizeBox     = $false
$form.BackColor       = [System.Drawing.ColorTranslator]::FromHtml("#1E293B")
$form.Font            = New-Object System.Drawing.Font("Segoe UI", 10)

# ── Tiêu đề ──────────────────────────────────────────────────────────────────
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text      = "🛠️  PHỤC HỒI HỆ SINH THÁI MICROSOFT"
$lblTitle.ForeColor = [System.Drawing.Color]::White
$lblTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$lblTitle.Location  = New-Object System.Drawing.Point(20, 18)
$lblTitle.Size      = New-Object System.Drawing.Size(470, 30)
$form.Controls.Add($lblTitle)

# ── Đường kẻ ngang ───────────────────────────────────────────────────────────
$sep = New-Object System.Windows.Forms.Label
$sep.BorderStyle = "Fixed3D"
$sep.Location    = New-Object System.Drawing.Point(20, 55)
$sep.Size        = New-Object System.Drawing.Size(470, 2)
$form.Controls.Add($sep)

# ── Nội dung mô tả ───────────────────────────────────────────────────────────
$lines = @(
    "Công cụ này sẽ giúp bạn:",
    "   1. Khôi phục và đăng ký lại Microsoft Store.",
    "   2. Cài đặt thư viện nền tảng VCLibs & UI.Xaml.",
    "   3. Cài đặt App Installer (Trình quản lý gói Winget)."
)
$y = 68
foreach ($line in $lines) {
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text      = $line
    $lbl.ForeColor = if ($line -match "^Công") {
        [System.Drawing.ColorTranslator]::FromHtml("#94A3B8")
    } else {
        [System.Drawing.ColorTranslator]::FromHtml("#E2E8F0")
    }
    $lbl.Location  = New-Object System.Drawing.Point(20, $y)
    $lbl.Size      = New-Object System.Drawing.Size(470, 22)
    $form.Controls.Add($lbl)
    $y += 24
}

# ── Label trạng thái ─────────────────────────────────────────────────────────
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text      = "Trạng thái: Đang chờ lệnh..."
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

# ── Nút bắt đầu ──────────────────────────────────────────────────────────────
$btn = New-Object System.Windows.Forms.Button
$btn.Text      = "🚀  BẮT ĐẦU PHỤC HỒI"
$btn.ForeColor = [System.Drawing.Color]::White
$btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#3B82F6")
$btn.FlatStyle = "Flat"
$btn.FlatAppearance.BorderSize = 0
$btn.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$btn.Location  = New-Object System.Drawing.Point(20, 238)
$btn.Size      = New-Object System.Drawing.Size(470, 48)
$btn.Cursor    = [System.Windows.Forms.Cursors]::Hand
$form.Controls.Add($btn)

# ── Biến chia sẻ thread-safe ─────────────────────────────────────────────────
$shared = [hashtable]::Synchronized(@{
    Status   = ""
    Progress = -1
    Done     = $false
    HasError = $false
})

# ── Script chạy nền ──────────────────────────────────────────────────────────
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
        SetUI "Đang xóa bộ nhớ đệm Microsoft Store (wsreset)..." 10
        Start-Process "wsreset.exe" -ArgumentList "-i" -WindowStyle Hidden -Wait -EA SilentlyContinue

        SetUI "Đang đăng ký lại nhân ứng dụng Store..." 25
        Get-AppxPackage -allusers Microsoft.WindowsStore -EA SilentlyContinue | ForEach-Object {
            Add-AppxPackage -DisableDevelopmentMode -Register "$($_.InstallLocation)\AppXManifest.xml" -EA SilentlyContinue
        }

        SetUI "Đang tải thư viện nền tảng VCLibs (x64)..." 40
        Install "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" "VCLibs.appx" "web"

        SetUI "Đang tải giao diện hệ thống UI.Xaml 2.8..." 55
        Install "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx" "UIXaml.appx" "web"

        SetUI "Đang tải trình quản lý gói App Installer (Winget)..." 70
        Install "https://aka.ms/getwinget" "AppInstaller.msixbundle" "stream"

        SetUI "Đang cấu hình hệ thống..." 90
        Start-Sleep -Seconds 2

        SetUI "✅ Hoàn tất! Hệ sinh thái Microsoft đã được phục hồi." 100
        $shared.Done = $true
    } catch {
        SetUI "❌ Có lỗi xảy ra: $_" 0
        $shared.HasError = $true
        $shared.Done     = $true
    }
}

# ── Timer polling UI ─────────────────────────────────────────────────────────
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 400

$script:timerHandler = {
    if ($shared.Status -ne "") {
        $lblStatus.Text = "Trạng thái: " + $shared.Status
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
            $btn.Text      = "❌  CÓ LỖI — BẤM ĐỂ THOÁT"
        } else {
            $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#10B981")
            $btn.Text      = "✅  HOÀN TẤT — BẤM ĐỂ THOÁT"
        }

        $btn.remove_Click($script:btnHandler)
        $btn.Add_Click({ $form.Close() })
        $btn.Enabled = $true
    }
}
$timer.Add_Tick($script:timerHandler)

# ── Handler nút bắt đầu ──────────────────────────────────────────────────────
$script:btnHandler = {
    $btn.Enabled   = $false
    $btn.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#475569")
    $btn.Text      = "⏳  ĐANG XỬ LÝ..."

    $script:rs = [runspacefactory]::CreateRunspace()
    $script:rs.Open()

    $script:ps = [powershell]::Create()
    $script:ps.Runspace = $script:rs
    [void]$script:ps.AddScript($workerScript).AddArgument($shared)
    [void]$script:ps.BeginInvoke()

    $timer.Start()
}
$btn.Add_Click($script:btnHandler)

# ── Chạy form ────────────────────────────────────────────────────────────────
[void]$form.ShowDialog()