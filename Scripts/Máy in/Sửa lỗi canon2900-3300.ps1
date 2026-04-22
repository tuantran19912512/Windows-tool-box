<#
.SYNOPSIS
    Canon LBP 2900/3300 - Fix Duplicate Port - GUI Windows
.NOTES
    Chay: Right-click -> Run with PowerShell (khong can Admin o buoc dau)
    Script tu yeu cau UAC khi can.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Tu yeu cau UAC neu chua co quyen Admin ─────────────────────────────────
$me = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $args0 = '-NoProfile -ExecutionPolicy Bypass -File "' + $MyInvocation.MyCommand.Path + '"'
    Start-Process powershell -Verb RunAs -ArgumentList $args0
    exit
}

$ErrorActionPreference = "SilentlyContinue"

# ══════════════════════════════════════════════════════════════════════════════
#  MAU SAC & FONT
# ══════════════════════════════════════════════════════════════════════════════
$clrBg      = [System.Drawing.Color]::FromArgb(245, 245, 245)
$clrPanel   = [System.Drawing.Color]::White
$clrBorder  = [System.Drawing.Color]::FromArgb(220, 220, 220)
$clrAccent  = [System.Drawing.Color]::FromArgb(0, 120, 212)
$clrSuccess = [System.Drawing.Color]::FromArgb(16, 124, 16)
$clrWarn    = [System.Drawing.Color]::FromArgb(196, 98, 0)
$clrDanger  = [System.Drawing.Color]::FromArgb(196, 43, 28)
$clrText    = [System.Drawing.Color]::FromArgb(32, 32, 32)
$clrMuted   = [System.Drawing.Color]::FromArgb(96, 96, 96)
$clrLogBg   = [System.Drawing.Color]::FromArgb(252, 252, 252)

$fntTitle   = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Regular)
$fntSub     = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Regular)
$fntBtn     = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Regular)
$fntLog     = New-Object System.Drawing.Font("Consolas", 8.5,[System.Drawing.FontStyle]::Regular)
$fntStep    = New-Object System.Drawing.Font("Segoe UI", 8.5,[System.Drawing.FontStyle]::Regular)
$fntBold    = New-Object System.Drawing.Font("Segoe UI", 9,  [System.Drawing.FontStyle]::Bold)

# ══════════════════════════════════════════════════════════════════════════════
#  CUA SO CHINH
# ══════════════════════════════════════════════════════════════════════════════
$form                  = New-Object System.Windows.Forms.Form
$form.Text             = "Canon LBP 2900/3300 — Sửa Lỗi Trùng Port"
$form.Size             = New-Object System.Drawing.Size(620, 710)
$form.MinimumSize      = New-Object System.Drawing.Size(620, 710)
$form.MaximumSize      = New-Object System.Drawing.Size(620, 710)
$form.StartPosition    = "CenterScreen"
$form.BackColor        = $clrBg
$form.FormBorderStyle  = "FixedSingle"
$form.MaximizeBox      = $false
$form.Font             = $fntSub

# ── Header panel ──────────────────────────────────────────────────────────────
$pnlHeader             = New-Object System.Windows.Forms.Panel
$pnlHeader.Size        = New-Object System.Drawing.Size(620, 72)
$pnlHeader.Location    = New-Object System.Drawing.Point(0, 0)
$pnlHeader.BackColor   = $clrAccent

$lblTitle              = New-Object System.Windows.Forms.Label
$lblTitle.Text         = "Canon LBP 2900 / 3300"
$lblTitle.Font         = $fntTitle
$lblTitle.ForeColor    = [System.Drawing.Color]::White
$lblTitle.Location     = New-Object System.Drawing.Point(20, 12)
$lblTitle.Size         = New-Object System.Drawing.Size(400, 26)

$lblSub                = New-Object System.Windows.Forms.Label
$lblSub.Text           = "Công cụ xử lý lỗi trùng port máy in — yêu cầu quyền Administrator"
$lblSub.Font           = $fntSub
$lblSub.ForeColor      = [System.Drawing.Color]::FromArgb(200, 230, 255)
$lblSub.Location       = New-Object System.Drawing.Point(20, 42)
$lblSub.Size           = New-Object System.Drawing.Size(560, 18)

$pnlHeader.Controls.AddRange(@($lblTitle, $lblSub))
$form.Controls.Add($pnlHeader)

# ── Steps panel ───────────────────────────────────────────────────────────────
$pnlSteps              = New-Object System.Windows.Forms.Panel
$pnlSteps.Size         = New-Object System.Drawing.Size(580, 130)
$pnlSteps.Location     = New-Object System.Drawing.Point(20, 84)
$pnlSteps.BackColor    = $clrPanel
$pnlSteps.BorderStyle  = "FixedSingle"

$stepLabels = @(
    "1. Dừng Spooler",
    "2. Xóa máy in",
    "3. Xóa driver",
    "4. Xóa port",
    "5. pnputil INF",
    "6. File driver",
    "7. Bật Spooler",
    "8. Xác nhận"
)
$stepPanels = @()
$COLS = 4; $ROWS = 2
$sw = 138; $sh = 52; $sg = 4
for ($i = 0; $i -lt 8; $i++) {
    $col = $i % $COLS; $row = [math]::Floor($i / $COLS)
    $sp  = New-Object System.Windows.Forms.Panel
    $sp.Size      = New-Object System.Drawing.Size($sw, $sh)
    $sp.Location  = New-Object System.Drawing.Point((8 + $col*($sw+$sg)), (8 + $row*($sh+$sg)))
    $sp.BackColor = [System.Drawing.Color]::FromArgb(248, 248, 248)
    $sp.BorderStyle = "FixedSingle"

    $lbl          = New-Object System.Windows.Forms.Label
    $lbl.Text     = $stepLabels[$i]
    $lbl.Font     = $fntStep
    $lbl.ForeColor= $clrMuted
    $lbl.Location = New-Object System.Drawing.Point(6, 8)
    $lbl.Size     = New-Object System.Drawing.Size(124, 36)
    $lbl.TextAlign= "MiddleLeft"

    $dot          = New-Object System.Windows.Forms.Panel
    $dot.Size     = New-Object System.Drawing.Size(8, 8)
    $dot.Location = New-Object System.Drawing.Point(($sw - 20), 6)
    $dot.BackColor= [System.Drawing.Color]::FromArgb(210, 210, 210)

    $sp.Controls.AddRange(@($lbl, $dot))
    $pnlSteps.Controls.Add($sp)
    $stepPanels += ,@($sp, $lbl, $dot)
}
$form.Controls.Add($pnlSteps)

# ── Progress bar ──────────────────────────────────────────────────────────────
$lblProgress           = New-Object System.Windows.Forms.Label
$lblProgress.Text      = "Sẵn sàng"
$lblProgress.Font      = $fntBold
$lblProgress.ForeColor = $clrText
$lblProgress.Location  = New-Object System.Drawing.Point(20, 226)
$lblProgress.Size      = New-Object System.Drawing.Size(400, 18)

$lblPct                = New-Object System.Windows.Forms.Label
$lblPct.Text           = "0%"
$lblPct.Font           = $fntBold
$lblPct.ForeColor      = $clrAccent
$lblPct.Location       = New-Object System.Drawing.Point(540, 226)
$lblPct.Size           = New-Object System.Drawing.Size(50, 18)
$lblPct.TextAlign      = "MiddleRight"

$progressBar                    = New-Object System.Windows.Forms.ProgressBar
$progressBar.Size               = New-Object System.Drawing.Size(580, 12)
$progressBar.Location           = New-Object System.Drawing.Point(20, 250)
$progressBar.Minimum            = 0
$progressBar.Maximum            = 8
$progressBar.Value              = 0
$progressBar.Style              = "Continuous"
$progressBar.ForeColor          = $clrAccent

$form.Controls.AddRange(@($lblProgress, $lblPct, $progressBar))

# ── Log box ───────────────────────────────────────────────────────────────────
$lblLogTitle           = New-Object System.Windows.Forms.Label
$lblLogTitle.Text      = "Nhật ký xử lý"
$lblLogTitle.Font      = $fntBold
$lblLogTitle.ForeColor = $clrText
$lblLogTitle.Location  = New-Object System.Drawing.Point(20, 274)
$lblLogTitle.Size      = New-Object System.Drawing.Size(200, 18)

$logBox                = New-Object System.Windows.Forms.RichTextBox
$logBox.Size           = New-Object System.Drawing.Size(580, 260)
$logBox.Location       = New-Object System.Drawing.Point(20, 296)
$logBox.BackColor      = $clrLogBg
$logBox.BorderStyle    = "FixedSingle"
$logBox.Font           = $fntLog
$logBox.ReadOnly       = $true
$logBox.ScrollBars     = "Vertical"
$logBox.WordWrap       = $false

$form.Controls.AddRange(@($lblLogTitle, $logBox))

# ── Stats bar ─────────────────────────────────────────────────────────────────
$pnlStats              = New-Object System.Windows.Forms.Panel
$pnlStats.Size         = New-Object System.Drawing.Size(580, 64)
$pnlStats.Location     = New-Object System.Drawing.Point(20, 560)
$pnlStats.BackColor    = $clrPanel
$pnlStats.BorderStyle  = "FixedSingle"

function Make-Stat {
    param($x, $label, $color)
    $p = New-Object System.Windows.Forms.Panel
    $p.Size      = New-Object System.Drawing.Size(190, 64)
    $p.Location  = New-Object System.Drawing.Point($x, 0)
    $p.BackColor = $clrPanel
    $n = New-Object System.Windows.Forms.Label
    $n.Text      = "0"
    $n.Font      = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Regular)
    $n.ForeColor = $color
    $n.Location  = New-Object System.Drawing.Point(14, 6)
    $n.Size      = New-Object System.Drawing.Size(70, 32)
    $n.AutoSize  = $false
    $l = New-Object System.Windows.Forms.Label
    $l.Text      = $label
    $l.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
    $l.ForeColor = $clrMuted
    $l.Location  = New-Object System.Drawing.Point(14, 40)
    $l.Size      = New-Object System.Drawing.Size(162, 20)
    $l.AutoSize  = $false
    $p.Controls.AddRange(@($n, $l))
    $pnlStats.Controls.Add($p)
    return $n
}
$numOK = Make-Stat   0  "Thành công"  $clrSuccess
$numRm = Make-Stat  194  "Đã xóa"      $clrDanger
$numWn = Make-Stat  388  "Cảnh báo"    $clrWarn

$form.Controls.Add($pnlStats)

# ── Buttons ───────────────────────────────────────────────────────────────────
$btnRun                = New-Object System.Windows.Forms.Button
$btnRun.Text           = "Chạy xử lý"
$btnRun.Size           = New-Object System.Drawing.Size(130, 34)
$btnRun.Location       = New-Object System.Drawing.Point(20, 638)
$btnRun.FlatStyle      = "Flat"
$btnRun.FlatAppearance.BorderColor = $clrAccent
$btnRun.FlatAppearance.BorderSize  = 1
$btnRun.BackColor      = $clrAccent
$btnRun.ForeColor      = [System.Drawing.Color]::White
$btnRun.Font           = $fntBtn
$btnRun.Cursor         = "Hand"

$btnClose              = New-Object System.Windows.Forms.Button
$btnClose.Text         = "Đóng"
$btnClose.Size         = New-Object System.Drawing.Size(80, 34)
$btnClose.Location     = New-Object System.Drawing.Point(498, 638)
$btnClose.FlatStyle    = "Flat"
$btnClose.FlatAppearance.BorderColor = $clrBorder
$btnClose.FlatAppearance.BorderSize  = 1
$btnClose.BackColor    = $clrPanel
$btnClose.ForeColor    = $clrText
$btnClose.Font         = $fntBtn
$btnClose.Cursor       = "Hand"
$btnClose.Add_Click({ $form.Close() })

$lblNext               = New-Object System.Windows.Forms.Label
$lblNext.Text          = ""
$lblNext.Font          = $fntSub
$lblNext.ForeColor     = $clrMuted
$lblNext.Location      = New-Object System.Drawing.Point(162, 644)
$lblNext.Size          = New-Object System.Drawing.Size(340, 22)

$form.Controls.AddRange(@($btnRun, $btnClose, $lblNext))

# ══════════════════════════════════════════════════════════════════════════════
#  HELPER LOG & UI UPDATE
# ══════════════════════════════════════════════════════════════════════════════
$okCnt = 0; $rmCnt = 0; $wnCnt = 0

function UI-Log {
    param([string]$msg, [string]$type = "info")
    $color = switch ($type) {
        "ok"   { $clrSuccess }
        "rm"   { $clrDanger  }
        "warn" { $clrWarn    }
        "head" { $clrAccent  }
        default{ $clrMuted   }
    }
    $ts = Get-Date -Format "HH:mm:ss"
    $logBox.SelectionStart  = $logBox.TextLength
    $logBox.SelectionLength = 0
    $logBox.SelectionColor  = [System.Drawing.Color]::FromArgb(160,160,160)
    $logBox.AppendText("[$ts] ")
    $logBox.SelectionColor  = $color
    $logBox.AppendText("$msg`n")
    $logBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function UI-SetStep {
    param([int]$idx, [string]$state)
    $sp  = $stepPanels[$idx][0]
    $lbl = $stepPanels[$idx][1]
    $dot = $stepPanels[$idx][2]
    switch ($state) {
        "active" {
            $sp.BackColor  = [System.Drawing.Color]::FromArgb(229, 241, 255)
            $lbl.ForeColor = $clrAccent
            $dot.BackColor = $clrAccent
        }
        "done" {
            $sp.BackColor  = [System.Drawing.Color]::FromArgb(234, 246, 234)
            $lbl.ForeColor = $clrSuccess
            $dot.BackColor = $clrSuccess
        }
        "warn" {
            $sp.BackColor  = [System.Drawing.Color]::FromArgb(255, 244, 229)
            $lbl.ForeColor = $clrWarn
            $dot.BackColor = $clrWarn
        }
        "error" {
            $sp.BackColor  = [System.Drawing.Color]::FromArgb(255, 236, 234)
            $lbl.ForeColor = $clrDanger
            $dot.BackColor = $clrDanger
        }
    }
    [System.Windows.Forms.Application]::DoEvents()
}

function UI-Progress {
    param([int]$step, [string]$msg)
    $progressBar.Value = $step
    $pct = [math]::Round(($step / 8) * 100)
    $lblPct.Text      = "$pct%"
    $lblProgress.Text = $msg
    [System.Windows.Forms.Application]::DoEvents()
}

function UI-Stats {
    $numOK.Text = "$okCnt"
    $numRm.Text = "$rmCnt"
    $numWn.Text = "$wnCnt"
    [System.Windows.Forms.Application]::DoEvents()
}

function Run-Safe {
    param([scriptblock]$sb, [int]$timeout = 8)
    $job  = Start-Job -ScriptBlock $sb
    $done = Wait-Job $job -Timeout $timeout
    if ($done) { $out = Receive-Job $job 2>$null; Remove-Job $job -Force; return $out }
    Stop-Job $job; Remove-Job $job -Force; return $null
}

# ══════════════════════════════════════════════════════════════════════════════
#  LOGIC XU LY CHINH
# ══════════════════════════════════════════════════════════════════════════════
$btnRun.Add_Click({
    $btnRun.Enabled = $false
    $logBox.Clear()
    $okCnt = 0; $rmCnt = 0; $wnCnt = 0
    for ($i=0;$i -lt 8;$i++) { UI-SetStep $i "" }
    UI-Stats

    # ── BUOC 1: Dung Spooler ────────────────────────────────────────────────
    UI-SetStep 0 "active"
    UI-Progress 1 "Dừng Print Spooler..."
    UI-Log "=== BƯỚC 1: Dừng Print Spooler ===" "head"

    $svcSt = (sc.exe query Spooler 2>$null) -join " "
    if ($svcSt -match "RUNNING") {
        sc.exe stop Spooler | Out-Null
        Start-Sleep -Milliseconds 2000
        UI-Log "Đã gửi lệnh dừng Spooler" "ok"; $okCnt++
    } else {
        UI-Log "Spooler đã dừng sẵn" "ok"; $okCnt++
    }

    $spoolDir   = "$env:SystemRoot\System32\spool\PRINTERS"
    $spoolFiles = @(Get-ChildItem "$spoolDir\*" -ErrorAction SilentlyContinue)
    if ($spoolFiles.Count -gt 0) {
        Remove-Item "$spoolDir\*" -Force -Recurse -ErrorAction SilentlyContinue
        UI-Log "Xóa $($spoolFiles.Count) file spool bị kẹt" "rm"; $rmCnt++
    } else {
        UI-Log "Không có file spool tồn định" "ok"; $okCnt++
    }
    UI-SetStep 0 "done"; UI-Stats

    # ── BUOC 2: Xoa may in ──────────────────────────────────────────────────
    UI-SetStep 1 "active"
    UI-Progress 2 "Xóa máy in Canon cũ..."
    UI-Log "=== BƯỚC 2: Xóa máy in Canon ===" "head"

    $prBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers"
    if (Test-Path $prBase) {
        $prKeys = @(Get-ChildItem $prBase -ErrorAction SilentlyContinue |
                    Where-Object { $_.PSChildName -match "Canon" })
        if ($prKeys.Count -gt 0) {
            foreach ($k in $prKeys) {
                Remove-Item $k.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                UI-Log "Xóa máy in: $($k.PSChildName)" "rm"; $rmCnt++
            }
            UI-SetStep 1 "done"
        } else {
            UI-Log "Không có máy in Canon" "ok"; $okCnt++
            UI-SetStep 1 "done"
        }
    } else {
        UI-Log "Không tìm thấy registry Printers" "warn"; $wnCnt++
        UI-SetStep 1 "warn"
    }
    UI-Stats

    # ── BUOC 3: Xoa driver ──────────────────────────────────────────────────
    UI-SetStep 2 "active"
    UI-Progress 3 "Xóa printer driver Canon..."
    UI-Log "=== BƯỚC 3: Xóa printer driver ===" "head"

    $driverBases = @(
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows x64\Drivers\Version-3",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Environments\Windows NT x86\Drivers\Version-3"
    )
    $drvCount = 0
    foreach ($db in $driverBases) {
        if (Test-Path $db) {
            $drvKeys = @(Get-ChildItem $db -ErrorAction SilentlyContinue |
                         Where-Object { $_.PSChildName -match "Canon" })
            foreach ($dk in $drvKeys) {
                Remove-Item $dk.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                UI-Log "Xóa driver: $($dk.PSChildName)" "rm"; $rmCnt++; $drvCount++
            }
        }
    }
    if ($drvCount -eq 0) { UI-Log "Không có driver Canon trong registry" "ok"; $okCnt++ }
    UI-SetStep 2 "done"; UI-Stats

    # ── BUOC 4: Xoa port ────────────────────────────────────────────────────
    UI-SetStep 3 "active"
    UI-Progress 4 "Xóa printer port cũ..."
    UI-Log "=== BƯỚC 4: Xóa printer port ===" "head"

    $monBase = "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Monitors"
    $portCount = 0
    if (Test-Path $monBase) {
        $monitors = @(Get-ChildItem $monBase -ErrorAction SilentlyContinue)
        foreach ($mon in $monitors) {
            $portsPath = "$($mon.PSPath)\Ports"
            if (Test-Path $portsPath) {
                $ports = @(Get-ChildItem $portsPath -ErrorAction SilentlyContinue |
                           Where-Object { $_.PSChildName -match "^USB\d|^CNUSB" })
                foreach ($pt in $ports) {
                    Remove-Item $pt.PSPath -Recurse -Force -ErrorAction SilentlyContinue
                    UI-Log "Xóa port: $($pt.PSChildName)" "rm"; $rmCnt++; $portCount++
                }
            }
        }
    }
    if ($portCount -eq 0) { UI-Log "Không có port USB Canon cần xóa" "ok"; $okCnt++ }
    UI-SetStep 3 "done"; UI-Stats

    # ── BUOC 5: pnputil ─────────────────────────────────────────────────────
    UI-SetStep 4 "active"
    UI-Progress 5 "Xóa INF driver bằng pnputil..."
    UI-Log "=== BƯỚC 5: pnputil /delete-driver ===" "head"
    UI-Log "Đang quét... (tối đa 8 giây)" "info"

    $pnpOut = Run-Safe -timeout 8 -sb { pnputil /enum-drivers 2>$null }
    if ($null -eq $pnpOut) {
        UI-Log "pnputil timeout — bỏ qua" "warn"; $wnCnt++
        UI-SetStep 4 "warn"
    } else {
        $pnpText = ($pnpOut -join "`n")
        $infList = @()
        $blocks  = $pnpText -split "(?=Published Name\s*:)"
        foreach ($b in $blocks) {
            if ($b -match "Canon") {
                if ($b -match "Published Name\s*:\s*(oem\d+\.inf)") { $infList += $Matches[1] }
            }
        }
        if ($infList.Count -gt 0) {
            foreach ($inf in $infList) {
                UI-Log "Xóa INF: $inf" "info"
                $r = Run-Safe -timeout 10 -sb ([scriptblock]::Create("pnputil /delete-driver $inf /uninstall /force 2>`$null"))
                if ($null -eq $r) { UI-Log "$inf timeout" "warn"; $wnCnt++ }
                else              { UI-Log "$inf đã xóa"  "rm";   $rmCnt++ }
            }
            UI-SetStep 4 "done"
        } else {
            UI-Log "Không có INF Canon trong pnputil" "ok"; $okCnt++
            UI-SetStep 4 "done"
        }
    }
    UI-Stats

    # ── BUOC 6: File driver ─────────────────────────────────────────────────
    UI-SetStep 5 "active"
    UI-Progress 6 "Dọn dẹp file driver còn sót..."
    UI-Log "=== BƯỚC 6: Xóa file driver ===" "head"

    $driverDirs = @(
        "$env:SystemRoot\System32\spool\drivers\x64\3",
        "$env:SystemRoot\System32\spool\drivers\W32X86\3"
    )
    $fileCount = 0
    foreach ($dd in $driverDirs) {
        if (Test-Path $dd) {
            $files = @(Get-ChildItem $dd -ErrorAction SilentlyContinue |
                       Where-Object { $_.Name -match "^CNAB|^CNLB|^CAPLB|^canon" })
            foreach ($f in $files) {
                Remove-Item $f.FullName -Force -ErrorAction SilentlyContinue
                if (-not (Test-Path $f.FullName)) {
                    UI-Log "Xóa file: $($f.Name)" "rm"; $rmCnt++; $fileCount++
                } else {
                    UI-Log "Đang dùng: $($f.Name)" "warn"; $wnCnt++
                }
            }
        }
    }
    if ($fileCount -eq 0) { UI-Log "Không có file driver Canon còn sót" "ok"; $okCnt++ }
    UI-SetStep 5 "done"; UI-Stats

    # ── BUOC 7: Bat Spooler ─────────────────────────────────────────────────
    UI-SetStep 6 "active"
    UI-Progress 7 "Khởi động lại Print Spooler..."
    UI-Log "=== BƯỚC 7: Bật Spooler ===" "head"

    sc.exe start Spooler | Out-Null
    Start-Sleep -Seconds 2
    $st = (sc.exe query Spooler 2>$null) -join " "
    if ($st -match "RUNNING") {
        UI-Log "Print Spooler đang chạy" "ok"; $okCnt++
        UI-SetStep 6 "done"
    } else {
        UI-Log "Spooler chưa chạy — sẽ tự bật sau khi restart" "warn"; $wnCnt++
        UI-SetStep 6 "warn"
    }
    UI-Stats

    # ── BUOC 8: Xac nhan ────────────────────────────────────────────────────
    UI-SetStep 7 "active"
    UI-Progress 8 "Xác nhận kết quả..."
    UI-Log "=== BƯỚC 8: Xác nhận ===" "head"

    $remain = @(Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Control\Print\Printers" -ErrorAction SilentlyContinue |
                Where-Object { $_.PSChildName -match "Canon" })
    if ($remain.Count -eq 0) {
        UI-Log "Registry Printers: sạch hoàn toàn" "ok"; $okCnt++
    } else {
        UI-Log "Còn $($remain.Count) key — sẽ mất sau khi restart" "warn"; $wnCnt++
    }

    $finalSt = (sc.exe query Spooler 2>$null) -join " "
    if ($finalSt -match "RUNNING") { UI-Log "Spooler: ĐANG CHẠY" "ok"; $okCnt++ }
    else                           { UI-Log "Spooler: ĐÃ DỮNG" "warn"; $wnCnt++ }

    UI-Log ">>> Hoàn tất! Vui lòng khời động lại máy tính." "ok"; $okCnt++
    UI-SetStep 7 "done"; UI-Stats

    # ── Hoan tat ────────────────────────────────────────────────────────────
    UI-Progress 8 "Hoàn tất"
    $lblPct.Text  = "100%"
    $lblNext.Text = "Khởi động lại máy → Cài lại driver Canon"
    $btnRun.Text  = "Chạy lại"
    $btnRun.Enabled = $true

    [System.Windows.Forms.MessageBox]::Show(
        "Dọn dẹp hoàn tất!`n`nBước tiếp theo:`n  1. Khởi động lại máy tính`n  2. Rút cáp USB máy in`n  3. Cài driver Canon LBP 2900/3300`n  4. Khi màn hình yêu cầu → Cắm USB vào",
        "Hoàn Tất",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
})

# ══════════════════════════════════════════════════════════════════════════════
$form.Add_Shown({ $form.Activate() })
[System.Windows.Forms.Application]::Run($form)