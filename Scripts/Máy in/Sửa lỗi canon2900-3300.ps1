<#
.SYNOPSIS
    Canon LBP 2900/3300 - Sửa Lỗi Trùng Port + Backup & Tự Cài Lại Driver
.NOTES
    Chạy: Right-click -> Run with PowerShell
    Script tự xin quyền Admin qua UAC.
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Tự xin UAC nếu chưa Admin ──────────────────────────────────────────────
$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList ('-NoProfile -ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '"')
    exit
}
$ErrorActionPreference = "SilentlyContinue"

# ══════════════════════════════════════════════════════════════════════════════
#  MÀU SẮC & FONT
# ══════════════════════════════════════════════════════════════════════════════
$clrBg      = [Drawing.Color]::FromArgb(245,245,245)
$clrPanel   = [Drawing.Color]::White
$clrBorder  = [Drawing.Color]::FromArgb(220,220,220)
$clrAccent  = [Drawing.Color]::FromArgb(0,120,212)
$clrSuccess = [Drawing.Color]::FromArgb(16,124,16)
$clrWarn    = [Drawing.Color]::FromArgb(196,98,0)
$clrDanger  = [Drawing.Color]::FromArgb(196,43,28)
$clrText    = [Drawing.Color]::FromArgb(32,32,32)
$clrMuted   = [Drawing.Color]::FromArgb(96,96,96)
$clrLogBg   = [Drawing.Color]::FromArgb(252,252,252)
$clrPurple  = [Drawing.Color]::FromArgb(90,60,180)

$fntTitle = New-Object Drawing.Font("Segoe UI",13,[Drawing.FontStyle]::Regular)
$fntSub   = New-Object Drawing.Font("Segoe UI",9, [Drawing.FontStyle]::Regular)
$fntBtn   = New-Object Drawing.Font("Segoe UI",9, [Drawing.FontStyle]::Regular)
$fntLog   = New-Object Drawing.Font("Consolas",8.5,[Drawing.FontStyle]::Regular)
$fntStep  = New-Object Drawing.Font("Segoe UI",8.5,[Drawing.FontStyle]::Regular)
$fntBold  = New-Object Drawing.Font("Segoe UI",9, [Drawing.FontStyle]::Bold)

# ══════════════════════════════════════════════════════════════════════════════
#  FORM CHÍNH  (620 × 760)
# ══════════════════════════════════════════════════════════════════════════════
$form               = New-Object Windows.Forms.Form
$form.Text          = "Canon LBP 2900/3300 — Sửa Lỗi Trùng Port"
$form.Size          = New-Object Drawing.Size(620,760)
$form.MinimumSize   = $form.Size
$form.MaximumSize   = $form.Size
$form.StartPosition = "CenterScreen"
$form.BackColor     = $clrBg
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox   = $false
$form.Font          = $fntSub

# ── Header ─────────────────────────────────────────────────────────────────
$pnlH = New-Object Windows.Forms.Panel
$pnlH.Size = New-Object Drawing.Size(620,72); $pnlH.Location = New-Object Drawing.Point(0,0)
$pnlH.BackColor = $clrAccent

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = "Canon LBP 2900 / 3300"; $lblTitle.Font = $fntTitle
$lblTitle.ForeColor = [Drawing.Color]::White
$lblTitle.Location = New-Object Drawing.Point(20,12); $lblTitle.Size = New-Object Drawing.Size(400,26)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = "Sao lưu driver → Dọn dẹp → Tự cài lại — yêu cầu quyền Administrator"
$lblSub.Font = $fntSub; $lblSub.ForeColor = [Drawing.Color]::FromArgb(200,230,255)
$lblSub.Location = New-Object Drawing.Point(20,42); $lblSub.Size = New-Object Drawing.Size(560,18)

$pnlH.Controls.AddRange(@($lblTitle,$lblSub)); $form.Controls.Add($pnlH)

# ── Steps panel (10 bước, 5×2) ────────────────────────────────────────────
$pnlSteps = New-Object Windows.Forms.Panel
$pnlSteps.Size = New-Object Drawing.Size(580,134)
$pnlSteps.Location = New-Object Drawing.Point(20,84)
$pnlSteps.BackColor = $clrPanel; $pnlSteps.BorderStyle = "FixedSingle"

$stepLabels = @(
    "1. Backup driver",
    "2. Dừng Spooler",
    "3. Xóa máy in",
    "4. Xóa driver",
    "5. Xóa port",
    "6. pnputil INF",
    "7. File driver",
    "8. Bật Spooler",
    "9. Cài lại driver",
    "10. Xác nhận"
)
$TOTAL_STEPS = 10
$stepPanels = @()
$sw=110; $sh=52; $sg=3; $COLS=5
for ($i=0;$i -lt $TOTAL_STEPS;$i++) {
    $col=$i%$COLS; $row=[math]::Floor($i/$COLS)
    $sp = New-Object Windows.Forms.Panel
    $sp.Size = New-Object Drawing.Size($sw,$sh)
    $sp.Location = New-Object Drawing.Point((6+$col*($sw+$sg)),(6+$row*($sh+$sg)))
    $sp.BackColor = [Drawing.Color]::FromArgb(248,248,248)
    $sp.BorderStyle = "FixedSingle"
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $stepLabels[$i]; $lbl.Font = $fntStep; $lbl.ForeColor = $clrMuted
    $lbl.Location = New-Object Drawing.Point(6,6); $lbl.Size = New-Object Drawing.Size(96,40)
    $lbl.TextAlign = "MiddleLeft"
    $dot = New-Object Windows.Forms.Panel
    $dot.Size = New-Object Drawing.Size(7,7)
    $dot.Location = New-Object Drawing.Point(($sw-16),5)
    $dot.BackColor = [Drawing.Color]::FromArgb(210,210,210)
    $sp.Controls.AddRange(@($lbl,$dot)); $pnlSteps.Controls.Add($sp)
    $stepPanels += ,@($sp,$lbl,$dot)
}
$form.Controls.Add($pnlSteps)

# ── Backup path row ────────────────────────────────────────────────────────
$lblBkPath = New-Object Windows.Forms.Label
$lblBkPath.Text = "Thư mục sao lưu driver:"; $lblBkPath.Font = $fntBold
$lblBkPath.ForeColor = $clrText
$lblBkPath.Location = New-Object Drawing.Point(20,230); $lblBkPath.Size = New-Object Drawing.Size(160,22)

$txtBkPath = New-Object Windows.Forms.TextBox
$txtBkPath.Text = "$env:USERPROFILE\Desktop\CanonDriver_Backup"
$txtBkPath.Font = $fntSub; $txtBkPath.Location = New-Object Drawing.Point(186,228)
$txtBkPath.Size = New-Object Drawing.Size(310,22); $txtBkPath.BorderStyle = "FixedSingle"

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = "…"; $btnBrowse.Font = $fntBtn
$btnBrowse.Size = New-Object Drawing.Size(36,24); $btnBrowse.Location = New-Object Drawing.Point(502,227)
$btnBrowse.FlatStyle = "Flat"
$btnBrowse.FlatAppearance.BorderColor = $clrBorder
$btnBrowse.FlatAppearance.BorderSize = 1
$btnBrowse.BackColor = $clrPanel; $btnBrowse.Cursor = "Hand"
$btnBrowse.Add_Click({
    $fd = New-Object Windows.Forms.FolderBrowserDialog
    $fd.Description = "Chọn thư mục sao lưu driver Canon"
    $fd.SelectedPath = $txtBkPath.Text
    if ($fd.ShowDialog() -eq "OK") { $txtBkPath.Text = $fd.SelectedPath }
})

$form.Controls.AddRange(@($lblBkPath,$txtBkPath,$btnBrowse))

# ── Progress ───────────────────────────────────────────────────────────────
$lblProgress = New-Object Windows.Forms.Label
$lblProgress.Text = "Sẵn sàng"; $lblProgress.Font = $fntBold; $lblProgress.ForeColor = $clrText
$lblProgress.Location = New-Object Drawing.Point(20,262); $lblProgress.Size = New-Object Drawing.Size(440,18)

$lblPct = New-Object Windows.Forms.Label
$lblPct.Text = "0%"; $lblPct.Font = $fntBold; $lblPct.ForeColor = $clrAccent
$lblPct.Location = New-Object Drawing.Point(540,262); $lblPct.Size = New-Object Drawing.Size(50,18)
$lblPct.TextAlign = "MiddleRight"

$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Size = New-Object Drawing.Size(580,12); $progressBar.Location = New-Object Drawing.Point(20,286)
$progressBar.Minimum=0; $progressBar.Maximum=$TOTAL_STEPS; $progressBar.Value=0
$progressBar.Style="Continuous"; $progressBar.ForeColor=$clrAccent

$form.Controls.AddRange(@($lblProgress,$lblPct,$progressBar))

# ── Log box ────────────────────────────────────────────────────────────────
$lblLogTitle = New-Object Windows.Forms.Label
$lblLogTitle.Text = "Nhật ký xử lý"; $lblLogTitle.Font = $fntBold; $lblLogTitle.ForeColor = $clrText
$lblLogTitle.Location = New-Object Drawing.Point(20,310); $lblLogTitle.Size = New-Object Drawing.Size(200,18)

$logBox = New-Object Windows.Forms.RichTextBox
$logBox.Size = New-Object Drawing.Size(580,250); $logBox.Location = New-Object Drawing.Point(20,332)
$logBox.BackColor=$clrLogBg; $logBox.BorderStyle="FixedSingle"; $logBox.Font=$fntLog
$logBox.ReadOnly=$true; $logBox.ScrollBars="Vertical"; $logBox.WordWrap=$false

$form.Controls.AddRange(@($lblLogTitle,$logBox))

# ── Stats ──────────────────────────────────────────────────────────────────
$pnlStats = New-Object Windows.Forms.Panel
$pnlStats.Size = New-Object Drawing.Size(580,64); $pnlStats.Location = New-Object Drawing.Point(20,592)
$pnlStats.BackColor=$clrPanel; $pnlStats.BorderStyle="FixedSingle"

function Make-Stat { param($x,$label,$color)
    $p = New-Object Windows.Forms.Panel; $p.Size = New-Object Drawing.Size(190,64)
    $p.Location = New-Object Drawing.Point($x,0); $p.BackColor=$clrPanel
    $n = New-Object Windows.Forms.Label; $n.Text="0"
    $n.Font = New-Object Drawing.Font("Segoe UI",18,[Drawing.FontStyle]::Regular)
    $n.ForeColor=$color; $n.Location=New-Object Drawing.Point(14,5)
    $n.Size=New-Object Drawing.Size(70,32); $n.AutoSize=$false
    $l = New-Object Windows.Forms.Label; $l.Text=$label
    $l.Font = New-Object Drawing.Font("Segoe UI",8.5,[Drawing.FontStyle]::Regular)
    $l.ForeColor=$clrMuted; $l.Location=New-Object Drawing.Point(14,40)
    $l.Size=New-Object Drawing.Size(162,20); $l.AutoSize=$false
    $p.Controls.AddRange(@($n,$l)); $pnlStats.Controls.Add($p); return $n
}
$numOK = Make-Stat   0 "Thành công" $clrSuccess
$numRm = Make-Stat 194 "Đã xóa"    $clrDanger
$numWn = Make-Stat 388 "Cảnh báo"  $clrWarn
$form.Controls.Add($pnlStats)

# ── Buttons ────────────────────────────────────────────────────────────────
$btnRun = New-Object Windows.Forms.Button
$btnRun.Text="▶  Chạy xử lý"; $btnRun.Size=New-Object Drawing.Size(140,34)
$btnRun.Location=New-Object Drawing.Point(20,672); $btnRun.FlatStyle="Flat"
$btnRun.FlatAppearance.BorderColor=$clrAccent; $btnRun.FlatAppearance.BorderSize=1
$btnRun.BackColor=$clrAccent; $btnRun.ForeColor=[Drawing.Color]::White
$btnRun.Font=$fntBtn; $btnRun.Cursor="Hand"

$btnOpenBk = New-Object Windows.Forms.Button
$btnOpenBk.Text="📁 Mở thư mục backup"; $btnOpenBk.Size=New-Object Drawing.Size(160,34)
$btnOpenBk.Location=New-Object Drawing.Point(170,672); $btnOpenBk.FlatStyle="Flat"
$btnOpenBk.FlatAppearance.BorderColor=$clrBorder; $btnOpenBk.FlatAppearance.BorderSize=1
$btnOpenBk.BackColor=$clrPanel; $btnOpenBk.ForeColor=$clrText
$btnOpenBk.Font=$fntBtn; $btnOpenBk.Cursor="Hand"; $btnOpenBk.Enabled=$false
$btnOpenBk.Add_Click({ if (Test-Path $txtBkPath.Text) { Start-Process explorer.exe $txtBkPath.Text } })

$btnClose = New-Object Windows.Forms.Button
$btnClose.Text="Đóng"; $btnClose.Size=New-Object Drawing.Size(80,34)
$btnClose.Location=New-Object Drawing.Point(518,672); $btnClose.FlatStyle="Flat"
$btnClose.FlatAppearance.BorderColor=$clrBorder; $btnClose.FlatAppearance.BorderSize=1
$btnClose.BackColor=$clrPanel; $btnClose.ForeColor=$clrText
$btnClose.Font=$fntBtn; $btnClose.Cursor="Hand"
$btnClose.Add_Click({ $form.Close() })

$form.Controls.AddRange(@($btnRun,$btnOpenBk,$btnClose))

# ══════════════════════════════════════════════════════════════════════════════
#  HÀM HELPER
# ══════════════════════════════════════════════════════════════════════════════
$okCnt=0; $rmCnt=0; $wnCnt=0

function UI-Log { param([string]$msg,[string]$type="info")
    $color = switch($type){
        "ok"    {$clrSuccess} "rm"   {$clrDanger} "warn" {$clrWarn}
        "head"  {$clrAccent}  "back" {$clrPurple} default{$clrMuted}
    }
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.SelectionStart=$logBox.TextLength; $logBox.SelectionLength=0
    $logBox.SelectionColor=[Drawing.Color]::FromArgb(160,160,160)
    $logBox.AppendText("[$ts] ")
    $logBox.SelectionColor=$color; $logBox.AppendText("$msg`n")
    $logBox.ScrollToCaret(); [Windows.Forms.Application]::DoEvents()
}

function UI-SetStep { param([int]$idx,[string]$state)
    $sp=$stepPanels[$idx][0]; $lbl=$stepPanels[$idx][1]; $dot=$stepPanels[$idx][2]
    switch($state){
        "active" {$sp.BackColor=[Drawing.Color]::FromArgb(229,241,255);$lbl.ForeColor=$clrAccent; $dot.BackColor=$clrAccent}
        "done"   {$sp.BackColor=[Drawing.Color]::FromArgb(234,246,234);$lbl.ForeColor=$clrSuccess;$dot.BackColor=$clrSuccess}
        "warn"   {$sp.BackColor=[Drawing.Color]::FromArgb(255,244,229);$lbl.ForeColor=$clrWarn;   $dot.BackColor=$clrWarn}
        "error"  {$sp.BackColor=[Drawing.Color]::FromArgb(255,236,234);$lbl.ForeColor=$clrDanger; $dot.BackColor=$clrDanger}
        "backup" {$sp.BackColor=[Drawing.Color]::FromArgb(240,235,255);$lbl.ForeColor=$clrPurple; $dot.BackColor=$clrPurple}
        default  {$sp.BackColor=[Drawing.Color]::FromArgb(248,248,248);$lbl.ForeColor=$clrMuted;  $dot.BackColor=[Drawing.Color]::FromArgb(210,210,210)}
    }
    [Windows.Forms.Application]::DoEvents()
}

function UI-Progress { param([int]$step,[string]$msg)
    $progressBar.Value=$step
    $lblPct.Text="$([math]::Round(($step/$TOTAL_STEPS)*100))%"
    $lblProgress.Text=$msg; [Windows.Forms.Application]::DoEvents()
}

function UI-Stats {
    $numOK.Text="$okCnt"; $numRm.Text="$rmCnt"; $numWn.Text="$wnCnt"
    [Windows.Forms.Application]::DoEvents()
}

function Run-Safe { param([scriptblock]$sb,[int]$timeout=8)
    $job=Start-Job -ScriptBlock $sb; $done=Wait-Job $job -Timeout $timeout
    if($done){$out=Receive-Job $job 2>$null;Remove-Job $job -Force;return $out}
    Stop-Job $job;Remove-Job $job -Force;return $null
}

# ══════════════════════════════════════════════════════════════════════════════
#  XỬ LÝ CHÍNH
# ══════════════════════════════════════════════════════════════════════════════
$btnRun.Add_Click({
    $btnRun.Enabled=$false; $btnOpenBk.Enabled=$false
    $logBox.Clear(); $okCnt=0;$rmCnt=0;$wnCnt=0
    for($i=0;$i -lt $TOTAL_STEPS;$i++){UI-SetStep $i ""}
    UI-Stats

    $backupRoot = $txtBkPath.Text.Trim()
    $script:backupInfPath = $null   # lưu đường dẫn INF để cài lại

    # ══ BƯỚC 1: BACKUP DRIVER ═════════════════════════════════════════════════
    UI-SetStep 0 "active"
    UI-Progress 1 "Sao lưu driver Canon..."
    UI-Log "=== BƯỚC 1: Sao lưu driver Canon ===" "head"

    # Tạo thư mục backup với timestamp
    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $backupRoot $ts

    # Quét source driver files từ spool\drivers
    $srcDirs = @(
        "$env:SystemRoot\System32\spool\drivers\x64\3",
        "$env:SystemRoot\System32\spool\drivers\W32X86\3"
    )
    $backedUp = 0
    foreach ($src in $srcDirs) {
        if (Test-Path $src) {
            $canonFiles = @(Get-ChildItem $src -ErrorAction SilentlyContinue |
                           Where-Object { $_.Name -match "CNAB|CNLB|CAPLB|canon|Canon" })
            if ($canonFiles.Count -gt 0) {
                $archName = Split-Path $src -Parent | Split-Path -Leaf   # x64 hoặc W32X86
                $destDir  = Join-Path $backupDir $archName
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
                foreach ($f in $canonFiles) {
                    Copy-Item $f.FullName -Destination $destDir -Force -ErrorAction SilentlyContinue
                    if (Test-Path (Join-Path $destDir $f.Name)) {
                        UI-Log "Backup: $($f.Name) [$archName]" "back"; $backedUp++
                    }
                }
            }
        }
    }

    # Backup INF files từ pnputil (quan trọng nhất để cài lại)
    UI-Log "Đang tìm file INF trong pnputil..." "info"
    $pnpEnum = Run-Safe -timeout 8 -sb { pnputil /enum-drivers 2>$null }
    $infBackupPath = $null
    if ($null -ne $pnpEnum) {
        $pnpText = ($pnpEnum -join "`n")
        $blocks  = $pnpText -split "(?=Published Name\s*:)"
        $infDir  = Join-Path $backupDir "INF"
        foreach ($b in $blocks) {
            if ($b -match "Canon") {
                if ($b -match "Published Name\s*:\s*(oem\d+\.inf)") {
                    $oem = $Matches[1]
                    $src = "$env:SystemRoot\System32\DriverStore\FileRepository"
                    # Tìm thư mục chứa INF tương ứng
                    $infFolders = @(Get-ChildItem $src -Directory -ErrorAction SilentlyContinue |
                                    Where-Object { $_.Name -match "canon|capt|cnlbp" })
                    foreach ($folder in $infFolders) {
                        $infFiles = @(Get-ChildItem $folder.FullName -Filter "*.inf" -ErrorAction SilentlyContinue)
                        foreach ($inf in $infFiles) {
                            New-Item -ItemType Directory -Path $infDir -Force | Out-Null
                            Copy-Item $folder.FullName -Destination $infDir -Recurse -Force -ErrorAction SilentlyContinue
                            $infBackupPath = $infDir
                            UI-Log "Backup INF folder: $($folder.Name)" "back"; $backedUp++
                        }
                    }
                }
            }
        }
    }

    # Tìm INF trực tiếp trong DriverStore nếu chưa có
    if ($null -eq $infBackupPath) {
        $driverStore = "$env:SystemRoot\System32\DriverStore\FileRepository"
        $canonFolders = @(Get-ChildItem $driverStore -Directory -ErrorAction SilentlyContinue |
                          Where-Object { $_.Name -match "cnlbp|capt|canon" })
        if ($canonFolders.Count -gt 0) {
            $infDir = Join-Path $backupDir "INF"
            New-Item -ItemType Directory -Path $infDir -Force | Out-Null
            foreach ($folder in $canonFolders) {
                Copy-Item $folder.FullName -Destination $infDir -Recurse -Force -ErrorAction SilentlyContinue
                UI-Log "Backup thư mục driver: $($folder.Name)" "back"; $backedUp++
            }
            $infBackupPath = $infDir
        }
    }

    if ($backedUp -gt 0) {
        $script:backupInfPath = $infBackupPath
        UI-Log "Đã sao lưu $backedUp mục vào: $backupDir" "ok"; $okCnt++
        UI-SetStep 0 "backup"
        $btnOpenBk.Enabled = $true
    } else {
        UI-Log "Không tìm thấy file driver Canon để sao lưu" "warn"; $wnCnt++
        UI-SetStep 0 "warn"
    }
    UI-Stats

    # ══ BƯỚC 2: DỪNG SPOOLER ══════════════════════════════════════════════════
    UI-SetStep 1 "active"
    UI-Progress 2 "Dừng Print Spooler..."
    UI-Log "=== BƯỚC 2: Dừng Print Spooler ===" "head"

    $svcSt = (sc.exe query Spooler 2>$null) -join " "
    if ($svcSt -match "RUNNING") {
        sc.exe stop Spooler | Out-Null; Start-Sleep -Milliseconds 2000
        UI-Log "Đã dừng Spooler" "ok"; $okCnt++
    } else { UI-Log "Spooler đã dừng sẵn" "ok"; $okCnt++ }

    $spoolFiles = @(Get-ChildItem "$env:SystemRoot\System32\spool\PRINTERS\*" -ErrorAction SilentlyContinue)
    if ($spoolFiles.Count -gt 0) {
        Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -Recurse -ErrorAction SilentlyContinue
        UI-Log "Xóa $($spoolFiles.Count) file spool bị kẹt" "rm"; $rmCnt++
    } else { UI-Log "Không có file spool tồn đọng" "ok"; $okCnt++ }
    UI-SetStep 1 "done"; UI-Stats

    # ══ BƯỚC 3: XÓA MÁY IN ════════════════════════════════════════════════════
    UI-SetStep 2 "active"
    UI-Progress 3 "Xóa máy in Canon cũ..."
    UI-Log "=== BƯỚC 3: Xóa máy in Canon ===" "head"

    $prBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers"
    if (Test-Path $prBase) {
        $prKeys = @(Get-ChildItem $prBase -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match "Canon" })
        if ($prKeys.Count -gt 0) {
            foreach ($k in $prKeys) {
                Remove-Item $k.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                UI-Log "Xóa máy in: $($k.PSChildName)" "rm"; $rmCnt++
            }
            UI-SetStep 2 "done"
        } else { UI-Log "Không có máy in Canon" "ok"; $okCnt++; UI-SetStep 2 "done" }
    } else { UI-Log "Không tìm thấy registry Printers" "warn"; $wnCnt++; UI-SetStep 2 "warn" }
    UI-Stats

    # ══ BƯỚC 4: XÓA DRIVER REG ════════════════════════════════════════════════
    UI-SetStep 3 "active"
    UI-Progress 4 "Xóa printer driver Canon..."
    UI-Log "=== BƯỚC 4: Xóa printer driver ===" "head"

    $drvBases = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows NT x86\Drivers\Version-3"
    )
    $drvCount=0
    foreach ($db in $drvBases) {
        if (Test-Path $db) {
            @(Get-ChildItem $db -ErrorAction SilentlyContinue | Where-Object {$_.PSChildName -match "Canon"}) | ForEach-Object {
                Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                UI-Log "Xóa driver: $($_.PSChildName)" "rm"; $rmCnt++; $drvCount++
            }
        }
    }
    if ($drvCount -eq 0) { UI-Log "Không có driver Canon trong registry" "ok"; $okCnt++ }
    UI-SetStep 3 "done"; UI-Stats

    # ══ BƯỚC 5: XÓA PORT ══════════════════════════════════════════════════════
    UI-SetStep 4 "active"
    UI-Progress 5 "Xóa printer port cũ..."
    UI-Log "=== BƯỚC 5: Xóa printer port ===" "head"

    $portCount=0
    $monBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors"
    if (Test-Path $monBase) {
        @(Get-ChildItem $monBase -ErrorAction SilentlyContinue) | ForEach-Object {
            $pp = "$($_.PSPath)\Ports"
            if (Test-Path $pp) {
                @(Get-ChildItem $pp -ErrorAction SilentlyContinue | Where-Object {$_.PSChildName -match "^USB\d|^CNUSB"}) | ForEach-Object {
                    Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    UI-Log "Xóa port: $($_.PSChildName)" "rm"; $rmCnt++; $portCount++
                }
            }
        }
    }
    if ($portCount -eq 0) { UI-Log "Không có port USB Canon cần xóa" "ok"; $okCnt++ }
    UI-SetStep 4 "done"; UI-Stats

    # ══ BƯỚC 6: PNPUTIL ═══════════════════════════════════════════════════════
    UI-SetStep 5 "active"
    UI-Progress 6 "Xóa INF driver bằng pnputil..."
    UI-Log "=== BƯỚC 6: pnputil /delete-driver ===" "head"
    UI-Log "Đang quét... (tối đa 8 giây)" "info"

    $pnpOut = Run-Safe -timeout 8 -sb { pnputil /enum-drivers 2>$null }
    if ($null -eq $pnpOut) {
        UI-Log "pnputil timeout — bỏ qua" "warn"; $wnCnt++; UI-SetStep 5 "warn"
    } else {
        $infList=@()
        ($pnpOut -join "`n") -split "(?=Published Name\s*:)" | ForEach-Object {
            if ($_ -match "Canon" -and $_ -match "Published Name\s*:\s*(oem\d+\.inf)") { $infList += $Matches[1] }
        }
        if ($infList.Count -gt 0) {
            foreach ($inf in $infList) {
                UI-Log "Xóa INF: $inf" "info"
                $r = Run-Safe -timeout 10 -sb ([scriptblock]::Create("pnputil /delete-driver $inf /uninstall /force 2>`$null"))
                if ($null -eq $r) { UI-Log "$inf timeout" "warn"; $wnCnt++ }
                else              { UI-Log "$inf đã xóa" "rm"; $rmCnt++ }
            }
            UI-SetStep 5 "done"
        } else { UI-Log "Không có INF Canon trong pnputil" "ok"; $okCnt++; UI-SetStep 5 "done" }
    }
    UI-Stats

    # ══ BƯỚC 7: FILE DRIVER ═══════════════════════════════════════════════════
    UI-SetStep 6 "active"
    UI-Progress 7 "Dọn dẹp file driver còn sót..."
    UI-Log "=== BƯỚC 7: Xóa file driver ===" "head"

    $fileCount=0
    @("$env:SystemRoot\System32\spool\drivers\x64\3","$env:SystemRoot\System32\spool\drivers\W32X86\3") | ForEach-Object {
        if (Test-Path $_) {
            @(Get-ChildItem $_ -ErrorAction SilentlyContinue | Where-Object {$_.Name -match "^CNAB|^CNLB|^CAPLB|^canon"}) | ForEach-Object {
                Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $_.FullName)) { UI-Log "Xóa file: $($_.Name)" "rm"; $rmCnt++; $fileCount++ }
                else { UI-Log "Đang dùng: $($_.Name)" "warn"; $wnCnt++ }
            }
        }
    }
    if ($fileCount -eq 0) { UI-Log "Không có file driver Canon còn sót" "ok"; $okCnt++ }
    UI-SetStep 6 "done"; UI-Stats

    # ══ BƯỚC 8: BẬT SPOOLER ═══════════════════════════════════════════════════
    UI-SetStep 7 "active"
    UI-Progress 8 "Khởi động lại Print Spooler..."
    UI-Log "=== BƯỚC 8: Bật Spooler ===" "head"

    sc.exe start Spooler | Out-Null; Start-Sleep -Seconds 2
    $st = (sc.exe query Spooler 2>$null) -join " "
    if ($st -match "RUNNING") {
        UI-Log "Print Spooler đang chạy" "ok"; $okCnt++; UI-SetStep 7 "done"
    } else {
        UI-Log "Spooler chưa chạy — sẽ tự bật sau restart" "warn"; $wnCnt++; UI-SetStep 7 "warn"
    }
    UI-Stats

    # ══ BƯỚC 9: CÀI LẠI DRIVER TỰ ĐỘNG ═══════════════════════════════════════
    UI-SetStep 8 "active"
    UI-Progress 9 "Cài lại driver Canon từ bản sao lưu..."
    UI-Log "=== BƯỚC 9: Tự cài lại driver ===" "head"

    $installed = $false
    if ($null -ne $script:backupInfPath -and (Test-Path $script:backupInfPath)) {
        # Tìm tất cả file .inf trong thư mục backup INF
        $infFiles = @(Get-ChildItem $script:backupInfPath -Filter "*.inf" -Recurse -ErrorAction SilentlyContinue |
                      Where-Object { $_.Name -match "cnlbp|capt|canon|CNLBP|CAPT|Canon" })
        if ($infFiles.Count -gt 0) {
            foreach ($inf in $infFiles) {
                UI-Log "Cài lại: $($inf.Name)" "info"
                $r = Run-Safe -timeout 30 -sb ([scriptblock]::Create(
                    "pnputil /add-driver '$($inf.FullName)' /install /subdirs 2>`$null"
                ))
                if ($null -eq $r) {
                    UI-Log "Timeout khi cài $($inf.Name) — thử pnputil thường..." "warn"; $wnCnt++
                    # Thử không có /install
                    $r2 = Run-Safe -timeout 20 -sb ([scriptblock]::Create(
                        "pnputil /add-driver '$($inf.FullName)' 2>`$null"
                    ))
                    if ($null -ne $r2) { UI-Log "Thêm INF thành công (không install): $($inf.Name)" "ok"; $okCnt++; $installed=$true }
                } else {
                    UI-Log "Đã cài lại: $($inf.Name)" "ok"; $okCnt++; $installed=$true
                }
            }
        } else {
            UI-Log "Không tìm thấy file .inf trong thư mục sao lưu" "warn"; $wnCnt++
        }
    } else {
        UI-Log "Không có bản sao lưu — bỏ qua bước cài lại" "warn"; $wnCnt++
    }

    if ($installed) {
        UI-Log "✓ Driver đã được cài lại thành công" "ok"; $okCnt++
        UI-SetStep 8 "done"
    } else {
        UI-Log "⚠ Cần cài driver thủ công từ trang Canon" "warn"
        UI-SetStep 8 "warn"
    }
    UI-Stats

    # ══ BƯỚC 10: XÁC NHẬN ════════════════════════════════════════════════════
    UI-SetStep 9 "active"
    UI-Progress 10 "Xác nhận kết quả..."
    UI-Log "=== BƯỚC 10: Xác nhận ===" "head"

    $remain = @(Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers" -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -match "Canon" })
    if ($remain.Count -eq 0) { UI-Log "Registry Printers: sạch hoàn toàn" "ok"; $okCnt++ }
    else { UI-Log "Còn $($remain.Count) key — sẽ mất sau restart" "warn"; $wnCnt++ }

    $finalSt = (sc.exe query Spooler 2>$null) -join " "
    if ($finalSt -match "RUNNING") { UI-Log "Spooler: ĐANG CHẠY" "ok"; $okCnt++ }
    else                           { UI-Log "Spooler: ĐÃ DỪNG"  "warn"; $wnCnt++ }

    if ($null -ne $script:backupInfPath) { UI-Log "Backup tại: $backupRoot" "back"; $okCnt++ }
    UI-Log ">>> Xong! Cắm USB máy in rồi khởi động lại để nhận máy in mới." "ok"; $okCnt++
    UI-SetStep 9 "done"; UI-Stats

    # ── Hoàn tất ─────────────────────────────────────────────────────────────
    UI-Progress 10 "Hoàn tất"
    $lblPct.Text = "100%"
    $btnRun.Text = "▶  Chạy lại"; $btnRun.Enabled = $true

    $msgInstalled = if ($installed) { "`n  ✓ Driver đã được cài lại tự động" }
                    else            { "`n  ⚠ Cần cài driver thủ công từ trang Canon" }

    [Windows.Forms.MessageBox]::Show(
        "Hoàn tất xử lý!$msgInstalled`n`nBước tiếp theo:`n  1. Cắm USB máy in vào`n  2. Khởi động lại máy tính`n  3. Windows sẽ tự nhận máy in",
        "Hoàn Tất",
        [Windows.Forms.MessageBoxButtons]::OK,
        [Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

$form.Add_Shown({ $form.Activate() })
[Windows.Forms.Application]::Run($form)