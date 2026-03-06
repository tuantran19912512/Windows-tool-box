# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicCaiPhanMem = {
    # --- CẤU HÌNH GITHUB ---
    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $rawUrl   = "https://raw.githubusercontent.com/$GH_USER/$GH_REPO/main/$GH_FILE"
    
    # Đường dẫn lưu file cục bộ (Trong thư mục AppData để không làm rác máy)
    $localPath = Join-Path $env:LOCALAPPDATA "DanhSachPhanMem_Local.csv"

    # --- ĐỊNH NGHĨA FONT ---
    $fontNut     = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $fontNoiDung = New-Object System.Drawing.Font("Segoe UI", 10)
    $fontNho     = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Italic)

    # --- KHỞI TẠO GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - CÀI ĐẶT PHẦN MỀM"; $form.Size = "800,720"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lvStore = New-Object System.Windows.Forms.ListView; $lvStore.Size = "740,400"; $lvStore.Location = "20,20"; $lvStore.View = "Details"; $lvStore.CheckBoxes = $true; $lvStore.FullRowSelect = $true; $lvStore.Font = $fontNoiDung; $lvStore.BorderStyle = "FixedSingle"
    [void]$lvStore.Columns.Add("TÊN ỨNG DỤNG", 400); [void]$lvStore.Columns.Add("TRẠNG THÁI", 250); [void]$lvStore.Columns.Add("ID", 0)
    
    $lblProgress = New-Object System.Windows.Forms.Label; $lblProgress.Text = "Sẵn sàng..."; $lblProgress.Location = "20,430"; $lblProgress.Size = "500,20"; $lblProgress.Font = $fontNho; $lblProgress.ForeColor = "Gray"
    $pgBar = New-Object System.Windows.Forms.ProgressBar; $pgBar.Location = "20,455"; $pgBar.Size = "740,20"; $pgBar.Style = "Continuous"
    
    $btnSync = New-Object System.Windows.Forms.Button; $btnSync.Text = "ĐỒNG BỘ TỪ CLOUD"; $btnSync.Size = "220,55"; $btnSync.Location = "210,530"; $btnSync.BackColor = "#455A64"; $btnSync.ForeColor = "White"; $btnSync.FlatStyle = "Flat"; $btnSync.Font = $fontNut
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "BẮT ĐẦU CÀI ĐẶT"; $btnInstall.Size = "330,55"; $btnInstall.Location = "430,530"; $btnInstall.BackColor = "#2196F3"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = $fontNut
    
    $form.Controls.AddRange(@($lvStore, $lblProgress, $pgBar, $btnSync, $btnInstall))

    # --- HÀM 1: TẢI FILE TỪ GITHUB VỀ MÁY ---
    function Sync-From-Cloud {
        $lblProgress.Text = "Đang đồng bộ dữ liệu mới nhất..."
        [System.Windows.Forms.Application]::DoEvents()
        try {
            $urlWithCacheBuster = $rawUrl + "?t=" + (Get-Date -Format "yyyyMMddHHmmss")
            Invoke-WebRequest -Uri $urlWithCacheBuster -OutFile $localPath -UseBasicParsing -TimeoutSec 10
            $lblProgress.Text = "Đã cập nhật bản mới từ Cloud."
            Load-Local-Data
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Không thể kết nối Cloud. Đang dùng dữ liệu cũ trên máy.")
            Load-Local-Data
        }
    }

    # --- HÀM 2: ĐỌC DỮ LIỆU TỪ FILE CỤC BỘ ---
    function Load-Local-Data {
        $lvStore.Items.Clear()
        if (Test-Path $localPath) {
            try {
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
            } catch {
                [System.Windows.Forms.MessageBox]::Show("Lỗi định dạng file nội bộ!")
            }
        } else {
            $lblProgress.Text = "Chưa có dữ liệu. Vui lòng bấm Đồng bộ."
        }
    }

    # --- SỰ KIỆN NÚT BẤM ---
    $btnSync.Add_Click({ Sync-From-Cloud })
    
    $btnInstall.Add_Click({
        $items = @($lvStore.CheckedItems); if ($items.Count -eq 0) { return }
        $btnInstall.Enabled = $false; $pgBar.Maximum = $items.Count; $pgBar.Value = 0
        for ($i=0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            $lblProgress.Text = "Đang cài: $($item.Text)..."
            $item.SubItems[1].Text = "Đang cài..."
            [System.Windows.Forms.Application]::DoEvents()
            
            $p = Start-Process "winget" -ArgumentList "install --id `"$($item.SubItems[2].Text)`" --silent --accept-package-agreements" -PassThru -NoNewWindow
            while (-not $p.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 100 }
            
            $item.SubItems[1].Text = if ($p.ExitCode -eq 0) { "Hoàn tất" } else { "Lỗi" }
            $pgBar.Value = $i + 1
        }
        $btnInstall.Enabled = $true
        $lblProgress.Text = "Xong!"
    })

    # Tự động nạp dữ liệu cũ khi mở, nếu không có thì mới đồng bộ
    if (Test-Path $localPath) { Load-Local-Data } else { Sync-From-Cloud }

    $form.ShowDialog() | Out-Null
}

&$LogicCaiPhanMem