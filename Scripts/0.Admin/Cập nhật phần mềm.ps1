# ==============================================================================
# VIETTOOLBOX ADMIN V127 - BẢN FULL VŨ KHÍ (CÓ DÒ LINK & TỰ PHÂN LOẠI)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Nâng cấp: Thêm chức năng tự động phân loại phần mềm, thêm cột Category.
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV127 = {
    if (-not $Global:GH_TOKEN) {
        [System.Windows.Forms.MessageBox]::Show("Thiếu GitHub Token ở Main! Hãy đăng nhập trước.", "Lỗi hệ thống")
        return
    }

    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"

    # --- GIAO DIỆN WPF HIỆN ĐẠI ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Admin V127" Width="1200" Height="920" WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="15" CaptionHeight="35" ResizeBorderThickness="7" /></WindowChrome.WindowChrome>
    <Border Background="#F4F7F9" CornerRadius="15" BorderBrush="#0D47A1" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            
            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="VietToolbox Admin V127 - Cloud Manager" Foreground="#888" VerticalAlignment="Center" Margin="5,0,0,0" FontWeight="Bold"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand"/><Button Name="btnClose" Grid.Column="2" Content="✕" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#D32F2F" FontWeight="Bold"/>
            </Grid>

            <Grid Grid.Row="1" Margin="0,10,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="400"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                
                <Border Grid.Column="0" Background="White" CornerRadius="12" Padding="20" Margin="0,0,15,0" BorderBrush="#E0E0E0" BorderThickness="1">
                    <StackPanel>
                        <TextBlock Text="QUẢN TRỊ PHẦN MỀM" FontWeight="Bold" Foreground="#1A237E" FontSize="22" Margin="0,0,0,10" HorizontalAlignment="Center"/>
                        <CheckBox Name="ChkDefault" Content="Mặc định chọn cài đặt" IsChecked="True" FontWeight="Bold" Foreground="#2E7D32" Margin="0,0,0,15"/>
                        
                        <TextBlock Text="Tên hiển thị:" FontSize="12" Foreground="#666"/>
                        <TextBox Name="TxtName" Height="32" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>
                        
                        <TextBlock Text="Phân loại (Category):" FontSize="12" Foreground="#666"/>
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                            <TextBox Name="TxtCategory" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                            <Button Name="BtnDoCategory" Grid.Column="1" Content="🏷️ Phân loại" Background="#E65100" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </Grid>
                        
                        <TextBlock Text="Winget ID:" FontSize="12" Foreground="#666"/>
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                            <TextBox Name="TxtWinget" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                            <Button Name="BtnDowinget" Grid.Column="1" Content="🔍 Dò Winget" Background="#0288D1" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </Grid>

                        <TextBlock Text="Link Tải (Direct URL):" FontSize="12" Foreground="#666" FontWeight="Bold"/>
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                            <TextBox Name="TxtUrl" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                            <Button Name="BtnDoUrl" Grid.Column="1" Content="🔗 Dò Link" Background="#00796B" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </Grid>

                        <TextBlock Text="Choco ID:" FontSize="12" Foreground="#666"/>
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                            <TextBox Name="TxtChoco" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                            <Button Name="BtnDoChoco" Grid.Column="1" Content="🪄 Dò Choco" Background="#9C27B0" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </Grid>

                        <TextBlock Text="GDrive ID / Khác:" FontSize="12" Foreground="#666"/>
                        <TextBox Name="TxtGDrive" Height="32" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>

                        <TextBlock Text="Silent Args:" FontSize="12" Foreground="#666"/>
                        <TextBox Name="TxtSilent" Height="32" Margin="0,5,0,15" VerticalContentAlignment="Center" Padding="5,0"/>

                        <Border Background="#FFF3E0" CornerRadius="8" Padding="10" Margin="0,0,0,20" BorderBrush="#FFCC80" BorderThickness="1">
                            <StackPanel>
                                <TextBlock Text="Link Logo (Icon URL):" FontSize="12" Foreground="#E65100" FontWeight="Bold" Margin="0,0,0,5"/>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
                                    <TextBox Name="TxtIcon" Height="30" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                                    <Button Name="BtnDoIcon" Grid.Column="1" Content="🖼️ Dò Logo" Background="#FB8C00" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                                    </Button>
                                </Grid>
                                <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,0">
                                    <Image Name="ImgPreview" Width="40" Height="40" Stretch="Uniform" Margin="0,0,10,0"/>
                                    <TextBlock Name="TxtPreviewStatus" Text="Chưa có Logo" VerticalAlignment="Center" FontSize="12" Foreground="#FF9800" FontWeight="SemiBold"/>
                                </StackPanel>
                            </StackPanel>
                        </Border>

                        <UniformGrid Columns="2" Height="45" Margin="0,0,0,15">
                            <Button Name="BtnAdd" Content="➕ THÊM MỚI" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,5,0" Cursor="Hand">
                                 <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                            <Button Name="BtnEdit" Content="📝 LƯU SỬA" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="5,0,0,0" Cursor="Hand">
                                 <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                        </UniformGrid>

                        <Button Name="BtnPush" Content="🚀 LƯU ĐỒNG BỘ LÊN GITHUB" Height="55" Background="#0D47A1" Foreground="White" FontSize="15" FontWeight="Bold" Cursor="Hand">
                             <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
                        </Button>
                    </StackPanel>
                </Border>

                <Border Grid.Column="1" Background="White" CornerRadius="12" Padding="15" BorderBrush="#E0E0E0" BorderThickness="1">
                    <Grid>
                        <Grid.RowDefinitions><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                        <DataGrid Name="DgList" AutoGenerateColumns="False" CanUserAddRows="False" SelectionMode="Single" BorderThickness="0" Background="White" RowHeight="35">
                            <DataGrid.Columns>
                                <DataGridCheckBoxColumn Header="Mặc định" Binding="{Binding Check, UpdateSourceTrigger=PropertyChanged}" Width="70"/>
                                <DataGridTemplateColumn Header="Logo" Width="50">
                                    <DataGridTemplateColumn.CellTemplate>
                                        <DataTemplate><Image Source="{Binding IconURL}" Width="24" Height="24"/></DataTemplate>
                                    </DataGridTemplateColumn.CellTemplate>
                                </DataGridTemplateColumn>
                                <DataGridTextColumn Header="Tên Phần Mềm" Binding="{Binding Name}" Width="150"/>
                                <DataGridTextColumn Header="Phân Loại" Binding="{Binding Category}" Width="100"/>
                                <DataGridTextColumn Header="Winget ID" Binding="{Binding WingetID}" Width="130"/>
                                <DataGridTextColumn Header="Link Tải" Binding="{Binding DownloadUrl}" Width="150"/>
                                <DataGridTextColumn Header="Choco ID" Binding="{Binding ChocoID}" Width="100"/>
                            </DataGrid.Columns>
                        </DataGrid>
                        
                        <Grid Grid.Row="1" Margin="0,15,0,0">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                            <TextBlock Name="TxtStatus" Text="Trạng thái: Sẵn sàng." VerticalAlignment="Center" FontSize="12" Foreground="#666"/>
                            <Button Name="BtnClear" Grid.Column="1" Content="🧹 LÀM TRỐNG" Width="120" Height="40" Background="#90A4AE" Foreground="White" FontWeight="Bold" Margin="0,0,10,0" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                            <Button Name="BtnDel" Grid.Column="2" Content="🗑️ XOÁ DÒNG" Width="120" Height="40" Background="#D32F2F" Foreground="White" FontWeight="Bold" Cursor="Hand">
                                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="6"/></Style></Button.Resources>
                            </Button>
                        </Grid>
                    </Grid>
                </Border>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $script:ListApp = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $dgList = $window.FindName("DgList"); $dgList.ItemsSource = $script:ListApp
    
    $chk = $window.FindName("ChkDefault"); $tName = $window.FindName("TxtName"); $tWin = $window.FindName("TxtWinget")
    $tCat = $window.FindName("TxtCategory"); $btnDoCat = $window.FindName("BtnDoCategory")
    $tUrl = $window.FindName("TxtUrl")
    $tCho = $window.FindName("TxtChoco"); $tGDr = $window.FindName("TxtGDrive"); $tSil = $window.FindName("TxtSilent")
    $tIco = $window.FindName("TxtIcon"); $txtStatus = $window.FindName("TxtStatus")
    $imgPreview = $window.FindName("ImgPreview"); $txtPreviewStatus = $window.FindName("TxtPreviewStatus")
    $btnDoUrl = $window.FindName("BtnDoUrl")

    $window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })
    $window.FindName("btnMinimize").Add_Click({ $window.WindowState = "Minimized" })
    $window.FindName("btnClose").Add_Click({ $window.Close() })

    # --- SỰ KIỆN NÚT TỰ ĐỘNG PHÂN LOẠI ---
    $btnDoCat.Add_Click({
        if (-not $tName.Text) {
            [System.Windows.Forms.MessageBox]::Show("Tuấn phải nhập Tên phần mềm trước để tự động phân loại!", "Nhắc nhở")
            return
        }
        $nameStr = $tName.Text.ToLower()
        $category = "Khác"
        
        if ($nameStr -match "chrome|edge|firefox|coccoc|brave|opera|browser") { $category = "Trình Duyệt" }
        elseif ($nameStr -match "zalo|telegram|messenger|skype|viber|discord|wechat|whatsapp") { $category = "Nhắn Tin" }
        elseif ($nameStr -match "office|word|excel|powerpoint|pdf|foxit|acrobat|unikey|evkey|mathtype") { $category = "Văn Phòng" }
        elseif ($nameStr -match "photoshop|illustrator|corel|premiere|camtasia|capcut|obs|lightroom|autocad") { $category = "Đồ Họa & Video" }
        elseif ($nameStr -match "idm|torrent|teracopy|download") { $category = "Tải Xuống" }
        elseif ($nameStr -match "kaspersky|avast|eset|defender|malwarebytes|bkav|antivirus") { $category = "Bảo Mật" }
        elseif ($nameStr -match "winrar|7-zip|bandizip|peazip") { $category = "Giải Nén" }
        elseif ($nameStr -match "teamviewer|ultraviewer|anydesk|rustdesk") { $category = "Điều Khiển Từ Xa" }
        elseif ($nameStr -match "visual studio|vscode|python|nodejs|git|docker|postman|sql|java") { $category = "Lập Trình" }
        elseif ($nameStr -match "steam|epic|garena|ea app|ubisoft|vng") { $category = "Game" }
        elseif ($nameStr -match "vlc|k-lite|spotify|itunes|kmplayer") { $category = "Đa Phương Tiện" }
        elseif ($nameStr -match "ccleaner|revo|your uninstaller|hwmonitor|cpuz|gpuz|rufus|partition") { $category = "Hệ Thống" }

        $tCat.Text = $category
    })

    # --- SỰ KIỆN PREVIEW LOGO ---
    $tIco.Add_TextChanged({
        if ($tIco.Text -match "^http") {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit(); $bmp.UriSource = New-Object System.Uri($tIco.Text, [System.UriKind]::Absolute); $bmp.EndInit()
                $imgPreview.Source = $bmp
                $txtPreviewStatus.Visibility = "Collapsed"
            } catch { 
                $imgPreview.Source = $null; $txtPreviewStatus.Visibility = "Visible"; $txtPreviewStatus.Text = "❌ Lỗi ảnh!"; $txtPreviewStatus.Foreground = "Red"
            }
        } else {
            $imgPreview.Source = $null; $txtPreviewStatus.Visibility = "Visible"; $txtPreviewStatus.Text = "Chưa có Logo"; $txtPreviewStatus.Foreground = "#FF9800"
        }
    })

    # --- HÀM TẢI DỮ LIỆU ---
    function Reload-Admin {
        $script:ListApp.Clear()
        try {
            $headers = @{"Authorization" = "token $Global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
            $csvData = $csvText.Trim() | ConvertFrom-Csv
            foreach ($a in $csvData) {
                $icon = ""; if ($a.PSObject.Properties.Match('IconURL').Count -gt 0) { $icon = $a.IconURL }
                $url = ""; if ($a.PSObject.Properties.Match('DownloadUrl').Count -gt 0) { $url = $a.DownloadUrl }
                $cat = ""; if ($a.PSObject.Properties.Match('Category').Count -gt 0) { $cat = $a.Category }
                
                $script:ListApp.Add([PSCustomObject]@{ Check = ($a.Check -match "True"); Name = $a.Name; Category = $cat; WingetID = $a.WingetID; ChocoID = $a.ChocoID; GDriveID = $a.GDriveID; SilentArgs = $a.SilentArgs; IconURL = $icon; DownloadUrl = $url })
            }
        } catch { }
    }

    # --- CÁC HÀM DÒ KHÁC ---
    function Show-IconPicker($appName) {
        $form = New-Object System.Windows.Forms.Form; $form.Text = "Dò Logo: $appName"; $form.Size = "450,180"; $form.StartPosition = "CenterParent"; $form.BackColor = "White"
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhập trang chủ phần mềm (VD: zalo.me, google.com):"; $lbl.Location = "20,20"; $lbl.AutoSize = $true; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"; $txt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "LẤY LOGO"; $btnOk.Location = "20,90"; $btnOk.Size = "150,35"; $btnOk.BackColor = "#FB8C00"; $btnOk.ForeColor = "White"; $btnOk.FlatStyle = "Flat"; $btnOk.DialogResult = "OK"
        $form.Controls.AddRange(@($lbl, $txt, $btnOk)); $form.AcceptButton = $btnOk
        if ($form.ShowDialog() -eq "OK" -and $txt.Text) { return "https://icon.horse/icon/$($txt.Text.Trim() -replace 'https://|http://|www\.', '' -split '/' | Select-Object -First 1)" }
        return $null
    }
    function Show-WingetPicker($appName) {
        if (!(Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
        $env:WINGET_DISABLE_PROGRESS = "true"
        $raw = (winget search "$appName" --accept-source-agreements 2>&1) -join "`n"
        $results = @(); $start = $false
        foreach ($line in ($raw -split "`n")) {
            if ($line -match "^---") { $start = $true; continue }
            if ($start -and $line -match '(?<Name>.+?)\s+(?<Id>[a-zA-Z0-9]+\.[a-zA-Z0-9\.]+)\s+(?<Version>\S+)') {
                $results += [PSCustomObject]@{ Id = $matches['Id'].Trim(); Name = $matches['Name'].Trim() }
            }
        }
        if ($results.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy!"); return $null }
        $picker = New-Object System.Windows.Forms.Form; $picker.Text = "Chọn Winget ID"; $picker.Size = "500,350"; $picker.StartPosition = "CenterParent"
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Dock = "Top"; $lb.Height = 250; $lb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        foreach ($r in $results) { [void]$lb.Items.Add("$($r.Id) | $($r.Name)") }
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "CHỐT ID"; $btnOk.Dock = "Bottom"; $btnOk.DialogResult = "OK"
        $picker.Controls.AddRange(@($lb, $btnOk))
        if ($picker.ShowDialog() -eq "OK" -and $lb.SelectedItem) { return $lb.SelectedItem.ToString().Split("|")[0].Trim() }
        return $null
    }
    function Show-ChocoPicker($appName) {
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) { return $null }
        $results = choco search ($appName -replace '\s+', '' -replace '[^a-zA-Z0-9\-]', '') --limit-output | Select-Object -First 10
        $picker = New-Object System.Windows.Forms.Form; $picker.Text = "Chọn Choco ID"; $picker.Size = "400,320"; $picker.StartPosition = "CenterParent"
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Dock = "Top"; $lb.Height = 200; $lb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        foreach ($res in $results) { if ($res -match "\|") { [void]$lb.Items.Add($res.Split("|")[0]) } }
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Dock = "Bottom"; $btnOk.DialogResult = "OK"
        $picker.Controls.AddRange(@($lb, $btnOk))
        if ($picker.ShowDialog() -eq "OK" -and $lb.SelectedItem) { return $lb.SelectedItem.ToString() }
        return $null
    }

    # --- SỰ KIỆN BẢNG GRID & NÚT LÀM TRỐNG ---
    $dgList.Add_SelectionChanged({
        if ($dgList.SelectedItem) {
            $chk.IsChecked = $dgList.SelectedItem.Check; $tName.Text = $dgList.SelectedItem.Name; $tWin.Text = $dgList.SelectedItem.WingetID
            $tUrl.Text = $dgList.SelectedItem.DownloadUrl; $tCat.Text = $dgList.SelectedItem.Category
            $tCho.Text = $dgList.SelectedItem.ChocoID; $tGDr.Text = $dgList.SelectedItem.GDriveID; $tSil.Text = $dgList.SelectedItem.SilentArgs; $tIco.Text = $dgList.SelectedItem.IconURL
        }
    })

    $window.FindName("BtnClear").Add_Click({ $chk.IsChecked=$true; $tName.Text=""; $tCat.Text=""; $tWin.Text=""; $tUrl.Text=""; $tCho.Text=""; $tGDr.Text=""; $tSil.Text=""; $tIco.Text=""; $dgList.SelectedItem = $null })
    $window.FindName("BtnDowinget").Add_Click({ if ($tName.Text) { $id = Show-WingetPicker $tName.Text; if ($id) { $tWin.Text = $id } } })
    $window.FindName("BtnDoChoco").Add_Click({ if ($tName.Text) { $id = Show-ChocoPicker $tName.Text; if ($id) { $tCho.Text = $id } } })
    $window.FindName("BtnDoIcon").Add_Click({ if ($tName.Text) { $link = Show-IconPicker $tName.Text; if ($link) { $tIco.Text = $link } } else { [System.Windows.Forms.MessageBox]::Show("Nhập Tên phần mềm trước!") } })

    # --- NÚT DÒ LINK TẢI TRỰC TIẾP TỪ WINGET ---
    $btnDoUrl.Add_Click({
        if (-not $tWin.Text) {
            [System.Windows.Forms.MessageBox]::Show("Tuấn phải nhập Winget ID trước hoặc bấm 'Dò Winget' đi đã!", "Thiếu ID")
            return
        }
        
        $btnDoUrl.Content = "⏳ Đang quét..."
        $btnDoUrl.IsEnabled = $false
        [System.Windows.Forms.Application]::DoEvents()

        $id = $tWin.Text.Trim()
        $foundUrl = ""
        $archs = @("x64", "x86", "neutral", "") 
        
        try {
            foreach ($arch in $archs) {
                if ($arch -eq "") {
                    $raw = winget.exe show --id $id --exact | Out-String
                } else {
                    $raw = winget.exe show --id $id --exact --architecture $arch | Out-String
                }
                
                if ($raw -match '(?im)Installer\s*Url:\s*(https?://[^\s]+)') {
                    $foundUrl = $Matches[1].Trim()
                    break 
                }
            }

            if ($foundUrl) {
                $tUrl.Text = $foundUrl
            } else {
                [System.Windows.Forms.MessageBox]::Show("Thằng Winget không có link tải cho app này (hoặc là hàng của Store). Tuấn hãy tự tải file ném lên Google Drive rồi dán link tay nhé!", "Tịt ngòi", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Lỗi khi truy vấn Winget!", "Lỗi")
        }

        $btnDoUrl.Content = "🔗 Dò Link"
        $btnDoUrl.IsEnabled = $true
    })

    # --- THÊM & SỬA DỮ LIỆU ---
    $window.FindName("BtnAdd").Add_Click({
        if ($tName.Text) {
            $script:ListApp.Add([PSCustomObject]@{ Check=$chk.IsChecked; Name=$tName.Text; Category=$tCat.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text; DownloadUrl=$tUrl.Text })
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    $window.FindName("BtnEdit").Add_Click({
        $idx = $dgList.SelectedIndex
        if ($idx -ge 0 -and $tName.Text) {
            $script:ListApp[$idx] = [PSCustomObject]@{ Check=$chk.IsChecked; Name=$tName.Text; Category=$tCat.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text; DownloadUrl=$tUrl.Text }
        }
    })

    $window.FindName("BtnDel").Add_Click({
        if ($dgList.SelectedIndex -ge 0) {
            $script:ListApp.RemoveAt($dgList.SelectedIndex)
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    # --- PUSH CSV LÊN GITHUB ---
    $window.FindName("BtnPush").Add_Click({
        try {
            $txtStatus.Text = "⏳ Đang kết nối..."
            
            # Đã thêm cột Category vào Header
            $csvStr = "Check,Name,Category,WingetID,ChocoID,GDriveID,SilentArgs,IconURL,DownloadUrl`n"
            foreach ($item in $script:ListApp) {
                $cName = $item.Name -replace ',', ' ' -replace '"', ''
                $cCat = $item.Category -replace ',', ' ' -replace '"', ''
                $csvStr += "$($item.Check),$cName,$cCat,$($item.WingetID),$($item.ChocoID),$($item.GDriveID),$($item.SilentArgs),$($item.IconURL),$($item.DownloadUrl)`n"
            }
            
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($csvStr.Trim())
            $base64 = [System.Convert]::ToBase64String($bytes) -replace "`r", "" -replace "`n", ""
            
            $headers = @{ "Authorization" = "token $Global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"; "User-Agent" = "VietToolbox" }
            
            $sha = ""
            try { 
                $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction Stop 
                if ($info.sha) { $sha = $info.sha }
            } catch { }
            
            if ($sha -eq "") {
                $jsonBody = '{"message":"Cập nhật danh sách + Phân Loại + Link Tải","content":"' + $base64 + '"}'
            } else {
                $jsonBody = '{"message":"Cập nhật danh sách + Phân Loại + Link Tải","content":"' + $base64 + '","sha":"' + $sha + '"}'
            }

            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $jsonBody -ContentType "application/json; charset=utf-8"
            
            $txtStatus.Text = "✅ Thành công!"
            [System.Windows.Forms.MessageBox]::Show("Đã lưu dữ liệu CÓ CHỨA PHÂN LOẠI & LINK TẢI lên Cloud thành công tuyệt đối!", "Xong", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Reload-Admin
        } catch { 
            $errMsg = $_.Exception.Message
            if ($_.Exception.Response) {
                try {
                    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                    $errMsg += "`nLý do: " + $reader.ReadToEnd()
                    $reader.Close()
                } catch { }
            }
            $txtStatus.Text = "❌ Lỗi!"
            [System.Windows.Forms.MessageBox]::Show("Vẫn bị lỗi 400? Xem chi tiết:`n`n$errMsg", "Cảnh báo", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    Reload-Admin; $window.ShowDialog() | Out-Null
}

&$LogicVietToolboxCloudV127