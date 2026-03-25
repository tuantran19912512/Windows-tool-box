# ==============================================================================
# VIETTOOLBOX V67 - MODULE CLIENT (NÂNG CẤP WINDOWS)
# Tác giả: Tuấn
# ==============================================================================

# 1. Ép hệ thống dùng chuẩn UTF-8 (Bản chuẩn cho PowerShell 5.1)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicVietToolboxClientV67 = {
    # 2. Cấu hình Link Cloud
    $UrlCSV = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhMucSKU.csv"
    $BaseZipUrl = "https://raw.githubusercontent.com/tuantran19912512/skuwin/main/"

    # 3. Giao diện WPF
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VietToolbox - Nâng Cấp Windows" Width="550" Height="500" 
        WindowStartupLocation="CenterScreen" Background="#F0F2F5" FontFamily="Segoe UI">
    <Grid Margin="25">
        <StackPanel>
            <TextBlock Text="NÂNG CẤP WINDOWS CLOUD" FontWeight="Bold" FontSize="20" Foreground="#1A237E" Margin="0,0,0,5"/>
            <Separator Margin="0,0,0,20"/>

            <Border Background="#E3F2FD" CornerRadius="10" Padding="15" Margin="0,0,0,20" BorderBrush="#BBDEFB" BorderThickness="1">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="🖥️ Phiên bản hiện tại:" FontWeight="Bold" Foreground="#1565C0" Margin="0,0,10,0"/>
                    <TextBlock Name="TxtCurrentVer" Text="Đang kiểm tra..." FontWeight="Bold" Foreground="#D32F2F"/>
                </StackPanel>
            </Border>

            <TextBlock Text="Chọn phiên bản muốn nâng cấp:" FontWeight="Bold" Margin="0,0,0,10"/>
            <ComboBox Name="CbEditions" Height="40" VerticalContentAlignment="Center" Padding="10,0" Margin="0,0,0,20">
                 <ComboBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></ComboBox.Resources>
            </ComboBox>

            <Button Name="BtnStart" Content="🚀 BẮT ĐẦU NÂNG CẤP" Height="60" Background="#1565C0" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
            </Button>

            <TextBlock Name="TxtLog" Text="Hệ thống sẵn sàng." FontSize="12" Foreground="#666" Margin="0,15,0,0" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center" FontWeight="SemiBold"/>
            <ProgressBar Name="ProgBar" Height="10" Margin="0,10,0,0" IsIndeterminate="True" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

    # Tải giao diện
    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $cb = $window.FindName("CbEditions")
    $btn = $window.FindName("BtnStart")
    $log = $window.FindName("TxtLog")
    $txtCurrent = $window.FindName("TxtCurrentVer")
    $pb = $window.FindName("ProgBar")

    # 4. NHẬN DẠNG WINDOWS HIỆN TẠI
    $currentEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    $txtCurrent.Text = $currentEdition

    # 5. TẢI VÀ LỌC DANH MỤC TỪ GITHUB
    try {
        $log.Text = "⏳ Đang đồng bộ danh mục từ Cloud..."
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8 # Ép UTF-8 khi tải file CSV
        $csvText = $wc.DownloadString($UrlCSV)
        $data = $csvText | ConvertFrom-Csv
        
        $cb.Items.Clear()
        foreach ($item in $data) {
            # Loại bỏ bản trùng với bản hiện tại
            if ($item.FileName -notmatch $currentEdition) {
                [void]$cb.Items.Add($item)
            }
        }
        
        $cb.DisplayMemberPath = "Name"
        if ($cb.Items.Count -gt 0) {
            $cb.SelectedIndex = 0
            $log.Text = "✅ Đã tải xong danh sách. Hệ thống đã ẩn bản $currentEdition."
        } else {
            $log.Text = "ℹ️ Bạn đang ở phiên bản cao nhất hoặc danh sách trống."
            $btn.IsEnabled = $false
        }
    } catch {
        $log.Text = "❌ Lỗi: Không thể kết nối Cloud để lấy danh sách SKU!"
    }

    # 6. XỬ LÝ NÂNG CẤP KHI BẤM NÚT (Dùng Start-Job chuẩn)
    $btn.Add_Click({
        $selected = $cb.SelectedItem
        if (-not $selected) { return }

        $msg = [System.Windows.MessageBox]::Show("Hệ thống sẽ tải SKU và nâng cấp lên $($selected.Name). Bạn có chắc chắn không?", "Xác nhận nâng cấp", "YesNo", "Information")
        if ($msg -ne "Yes") { return }

        $btn.IsEnabled = $false
        $pb.Visibility = "Visible"
        $log.Text = "⏳ Đang khởi tạo quá trình tải dữ liệu..."

        # ScriptBlock chạy ngầm bằng Start-Job
        $JobCode = {
            param($url, $key, $name)
            try {
                $tempZip = "$env:TEMP\upgrade_sku.zip"
                $tempDir = "$env:TEMP\SKU_Extract"
                
                # A. Tải file
                $web = New-Object System.Net.WebClient
                $web.DownloadFile($url, $tempZip)
                
                # B. Giải nén
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
                Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
                
                # C. Nạp chứng chỉ
                $files = Get-ChildItem -Path $tempDir -Filter "*.xrm-ms" -Recurse
                foreach ($f in $files) {
                    $null = cscript //nologo C:\Windows\System32\slmgr.vbs /ilc "$($f.FullName)"
                }
                
                # D. Kích hoạt
                Start-Process "changepk.exe" -ArgumentList "/ProductKey $key" -Wait
                return "✅ THÀNH CÔNG: Đã gửi lệnh nâng cấp lên $name!"
            } catch {
                return "❌ LỖI: $($_.Exception.Message)"
            }
        }

        # Khởi chạy Job (Dùng $script: để Timer có thể đọc được biến này)
        $DownloadUrl = $BaseZipUrl + $selected.FileName
        $script:currentJob = Start-Job -ScriptBlock $JobCode -ArgumentList $DownloadUrl, $selected.GenericKey, $selected.Name
        
        $log.Text = "🚀 Đang tải và nạp cấu hình... Vui lòng không tắt Tool!"

        # Bộ đếm thời gian kiểm tra Job
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Add_Tick({
            # Lấy đúng ID từ biến $script:currentJob
            $jobStatus = Get-Job -Id $script:currentJob.Id
            
            if ($jobStatus.State -ne "Running") {
                $result = Receive-Job -Job $jobStatus
                $log.Text = $result
                $pb.Visibility = "Collapsed"
                $btn.IsEnabled = $true
                $timer.Stop()
                
                # Dọn dẹp Job sau khi xong
                Remove-Job -Id $script:currentJob.Id
                
                if ($result -match "THÀNH CÔNG") {
                    [System.Windows.MessageBox]::Show("Quá trình cài đặt SKU đã xong. Hệ thống có thể sẽ khởi động lại để hoàn tất nâng cấp!", "Thông báo", "OK", "Information")
                }
            }
        })
        $timer.Start()
    })

    $window.ShowDialog() | Out-Null
}

&$LogicVietToolboxClientV67