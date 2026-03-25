Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicVietToolboxClientV67 = {
    # 1. Khai báo Link Cloud của Tuấn
    $UrlCSV = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhMucSKU.csv"
    $BaseZipUrl = "https://raw.githubusercontent.com/tuantran19912512/skuwin/main/"

    # 2. Giao diện WPF
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox - Windows Upgrade" Width="550" Height="500" WindowStartupLocation="CenterScreen" Background="#F0F2F5">
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

            <TextBlock Name="TxtLog" Text="Hệ thống sẵn sàng." FontSize="11" Foreground="#666" Margin="0,15,0,0" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center"/>
            <ProgressBar Name="ProgBar" Height="10" Margin="0,10,0,0" IsIndeterminate="True" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $cb = $window.FindName("CbEditions"); $btn = $window.FindName("BtnStart")
    $log = $window.FindName("TxtLog"); $txtCurrent = $window.FindName("TxtCurrentVer")
    $pb = $window.FindName("ProgBar")

    # --- BƯỚC 1: NHẬN DẠNG WINDOWS HIỆN TẠI ---
    $currentEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    $txtCurrent.Text = $currentEdition

    # --- BƯỚC 2: TẢI DANH MỤC VÀ LỌC TRÙNG ---
    try {
        $log.Text = "⏳ Đang đồng bộ danh mục từ Cloud..."
        $data = (New-Object System.Net.WebClient).DownloadString($UrlCSV) | ConvertFrom-Csv
        
        $cb.Items.Clear()
        foreach ($item in $data) {
            # Kiểm tra: Nếu FileName chứa tên bản hiện tại (ví dụ 'Professional') thì bỏ qua
            if ($item.FileName -notmatch $currentEdition) {
                [void]$cb.Items.Add($item)
            }
        }
        
        $cb.DisplayMemberPath = "Name"
        if ($cb.Items.Count -gt 0) {
            $cb.SelectedIndex = 0
            $log.Text = "✅ Đã lọc bỏ bản $currentEdition khỏi danh sách nâng cấp."
        } else {
            $log.Text = "ℹ️ Bạn đang ở phiên bản cao nhất hoặc danh sách trống."
            $btn.IsEnabled = $false
        }
    } catch {
        $log.Text = "❌ Lỗi: Không thể kết nối GitHub để lấy danh sách SKU!"
    }

    # --- XỬ LÝ NÂNG CẤP (Bản Fix lỗi Start-ThreadJob) ---
    $btn.Add_Click({
        $selected = $cb.SelectedItem
        if (-not $selected) { return }

        $msg = [System.Windows.MessageBox]::Show("Hệ thống sẽ tải SKU và nâng cấp lên $($selected.Name). Bạn có chắc chắn không?", "VietToolbox Xác Nhận", "YesNo", "Information")
        if ($msg -ne "Yes") { return }

        $btn.IsEnabled = $false
        $pb.Visibility = "Visible"
        $log.Text = "⏳ Đang khởi tạo quá trình nâng cấp..."

        # Dùng ScriptBlock để chạy ngầm bằng Start-Job (Có sẵn trên mọi máy)
        $JobCode = {
            param($url, $key, $name)
            try {
                $tempZip = "$env:TEMP\upgrade.zip"
                $tempDir = "$env:TEMP\SKU_Work"
                
                # 1. Tải file
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile($url, $tempZip)
                
                # 2. Giải nén
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
                Expand-Archive $tempZip -DestinationPath $tempDir -Force
                
                # 3. Nạp chứng chỉ .xrm-ms
                $files = Get-ChildItem -Path $tempDir -Filter "*.xrm-ms" -Recurse
                foreach ($f in $files) {
                    $null = cscript //nologo C:\Windows\System32\slmgr.vbs /ilc "$($f.FullName)"
                }
                
                # 4. Kích hoạt chuyển bản (Dùng Start-Process để không treo Job)
                Start-Process "changepk.exe" -ArgumentList "/ProductKey $key" -Wait
                return "✅ Thành công: Đã nâng cấp lên $name!"
            } catch {
                return "❌ Lỗi: $($_.Exception.Message)"
            }
        }

        # Chạy Job ngầm
        $currentJob = Start-Job -ScriptBlock $JobCode -ArgumentList ($BaseZipUrl + $selected.FileName), $selected.GenericKey, $selected.Name
        
        $log.Text = "🚀 Đang tải dữ liệu và nạp SKU... Vui lòng không tắt Tool!"

        # Kiểm tra trạng thái Job (Không làm treo giao diện)
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Add_Tick({
            $jobStatus = Get-Job -Id $currentJob.Id
            if ($jobStatus.State -ne "Running") {
                $result = Receive-Job -Job $jobStatus
                $log.Text = $result
                $pb.Visibility = "Collapsed"
                $btn.IsEnabled = $true
                $timer.Stop()
                
                # Dọn dẹp rác
                Remove-Job -Id $currentJob.Id
            }
        })
        $timer.Start()
    })

&$LogicVietToolboxClientV67