# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# --- KIỂM TRA QUYỀN ADMIN ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Vui lòng chạy VietToolbox bằng quyền Administrator để cài phần mềm!", "Thiếu quyền Admin")
    return
}

$LogicCaiPhanMem = {
    # =========================================================================
    # --- BƯỚC 0: KIỂM TRA VÀ TỰ ĐỘNG CÀI ĐẶT WINGET CHO WIN CŨ ---
    # =========================================================================
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        $hoi = [System.Windows.Forms.MessageBox]::Show("Hệ thống phát hiện máy tính này đang dùng Windows bản cũ và chưa có lõi Winget (App Installer).`n`nÔng có muốn VietToolbox tự động tải và cài đặt lõi Winget từ Microsoft không?", "Cảnh báo thiếu thư viện", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
        
        if ($hoi -eq "Yes") {
            try {
                $wingetUrl = "https://aka.ms/getwinget"
                $wingetPath = Join-Path $env:TEMP "winget.msixbundle"
                
                # Tạo form nhỏ để báo đang tải vì file có thể nặng 20MB
                $frmDl = New-Object System.Windows.Forms.Form; $frmDl.Size = "300,100"; $frmDl.StartPosition = "CenterScreen"; $frmDl.ControlBox = $false; $frmDl.Text = "Đang tải lõi Winget..."
                $lblDl = New-Object System.Windows.Forms.Label; $lblDl.Text = "Vui lòng đợi vài giây..."; $lblDl.Location = "20,20"; $lblDl.Size = "260,20"
                $frmDl.Controls.Add($lblDl); $frmDl.Show()
                [System.Windows.Forms.Application]::DoEvents()

                # Tải và cài đặt
                $web = New-Object System.Net.WebClient
                $web.DownloadFile($wingetUrl, $wingetPath)
                Add-AppxPackage -Path $wingetPath
                
                $frmDl.Close()
                [System.Windows.Forms.MessageBox]::Show("Đã tiêm lõi Winget thành công!`nĐể hệ thống nhận diện, vui lòng bấm OK và mở lại chức năng Cài Đặt Phần Mềm.", "Thành công", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
                return # Thoát ra để biến môi trường (Environment Path) của Windows kịp cập nhật
            } catch {
                if ($frmDl) { $frmDl.Close() }
                [System.Windows.Forms.MessageBox]::Show("Không thể tự động cài đặt Winget do bản Windows này quá cũ hoặc thiếu thư viện VCLibs.`n`nVui lòng mở Microsoft Store và cập nhật ứng dụng 'App Installer' theo cách thủ công.", "Lỗi hệ thống", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
                return
            }
        } else {
            return # Không cài Winget thì không thể chạy Tool, đành thoát
        }
    }


    # =========================================================================
    # --- BƯỚC 1: KHỞI TẠO GIAO DIỆN & LOGIC CÀI PHẦN MỀM (NHƯ CŨ) ---
    # =========================================================================
    $rawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachPhanMem.csv"
    $localPath = Join-Path $env:LOCALAPPDATA "DanhSachPhanMem_Local.csv"

    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - CÀI ĐẶT PHẦN MỀM TỰ ĐỘNG"; $form.Size = "800,720"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lvStore = New-Object System.Windows.Forms.ListView; $lvStore.Size = "740,400"; $lvStore.Location = "20,20"; $lvStore.View = "Details"; $lvStore.CheckBoxes = $true; $lvStore.FullRowSelect = $true; $lvStore.Font = $fontNoiDung; $lvStore.BorderStyle = "FixedSingle"
    [void]$lvStore.Columns.Add("TÊN ỨNG DỤNG", 400); [void]$lvStore.Columns.Add("TRẠNG THÁI", 250); [void]$lvStore.Columns.Add("ID", 0)
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,430"; $lblProgress.Size = "500,20"; $lblProgress.Font = $fontNho; $lblProgress.ForeColor = "Gray"
    
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,455"; $pgBar.Size = "740,20"; $pgBar.Style = "Continuous"
    
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "ĐỒNG BỘ TỪ CLOUD"; $btnSync.Size = "220,55"; $btnSync.Location = "210,530"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "330,55"; $btnInstall.Location = "430,530"; $btnInstall.BackColor = "#2196F3"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    
    $form.Controls.AddRange(@($lvStore, $lblProgress, $pgBar, $btnSync, $btnInstall))

    function Sync-From-Cloud {
        $lblProgress.Text = "Đang tải danh sách từ Cloud..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            $urlWithCacheBuster = $rawUrl + "?t=" + (Get-Date -Format "yyyyMMddHHmmss")
            $web = New-Object System.Net.WebClient
            $web.Headers.Add("User-Agent", "Mozilla/5.0")
            $web.DownloadFile($urlWithCacheBuster, $localPath)
            $lblProgress.Text = "Cập nhật thành công."
            Load-Local-Data
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi kết nối Cloud!")
            Load-Local-Data
        }
    }

    function Load-Local-Data {
        $lvStore.Items.Clear()
        if (Test-Path $localPath) {
            $csvData = Import-Csv -Path $localPath -Encoding UTF8
            foreach ($row in $csvData) {
                if ($row.Name) {
                    $li = New-Object System.Windows.Forms.ListViewItem($row.Name)
                    $li.Checked = ($row.Check -match "True")
                    [void]$li.SubItems.Add("Sẵn sàng")
                    [void]$li.SubItems.Add($row.ID)
                    $lvStore.Items.Add($li)
                }
            }
        }
    }

    $btnInstall.Add_Click({
        $items = @($lvStore.CheckedItems)
        if ($items.Count -eq 0) { return }
        
        $btnInstall.Enabled = $false
        $pgBar.Style = "Marquee"; $pgBar.MarqueeAnimationSpeed = 30

        foreach ($item in $items) {
            $appID = $item.SubItems[2].Text
            
            $item.SubItems[1].Text = "⏳ Đang cài..."
            $lblProgress.Text = "Đang cài đặt: $($item.Text)..."
            
            $lvStore.Refresh(); $lblProgress.Refresh()
            [System.Windows.Forms.Application]::DoEvents()

            Global:Ghi-Log ">>> Bắt đầu cài đặt: $($item.Text)"
            Start-Sleep -Seconds 1

            try {
                # Cửa sổ dòng lệnh chạy tiến độ tải %
                $args = "install --id `"$appID`" --silent --accept-package-agreements --accept-source-agreements --force"
                $process = Start-Process "winget" -ArgumentList $args -WindowStyle Normal -PassThru
                
                if ($process) {
                    while (-not $process.HasExited) {
                        [System.Windows.Forms.Application]::DoEvents()
                        Start-Sleep -Milliseconds 200
                    }
                    
                    if ($process.ExitCode -eq 0) {
                        $item.SubItems[1].Text = "✅ Hoàn tất"
                        Global:Ghi-Log "--- Cài đặt thành công: $($item.Text)"
                    } else {
                        $item.SubItems[1].Text = "❌ Lỗi ($($process.ExitCode))"
                        Global:Ghi-Log "!!! LỖI: $($item.Text) thất bại. Mã lỗi: $($process.ExitCode)"
                    }
                } else {
                    $item.SubItems[1].Text = "❌ Lỗi (Winget)"
                }
            } catch {
                $item.SubItems[1].Text = "❌ Lỗi hệ thống"
                Global:Ghi-Log "!!! LỖI NGHIÊM TRỌNG: $($_.Exception.Message)"
            }
            
            $lvStore.Refresh()
        }
        
        $pgBar.Style = "Continuous"; $pgBar.Maximum = 100; $pgBar.Value = 100
        $btnInstall.Enabled = $true
        $lblProgress.Text = "Đã xử lý xong danh sách!"
    })

    $btnSync.Add_Click({ Sync-From-Cloud })
    if (Test-Path $localPath) { Load-Local-Data } else { Sync-From-Cloud }
    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMem