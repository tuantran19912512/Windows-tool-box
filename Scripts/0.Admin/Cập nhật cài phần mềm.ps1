# ==============================================================================
# VIETTOOLBOX ADMIN V124.2 - BẢN WPF HIỆN ĐẠI (PREVIEW LOGO BẢN TO)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV124 = {
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
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Admin V124.2 - Cloud Manager" Width="1100" Height="800" WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.ColumnDefinitions><ColumnDefinition Width="380"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
        
        <Border Grid.Column="0" Background="White" CornerRadius="12" Padding="20" Margin="0,0,15,0" BorderBrush="#E0E0E0" BorderThickness="1">
            <StackPanel>
                <TextBlock Text="QUẢN TRỊ PHẦN MỀM" FontWeight="Bold" Foreground="#1A237E" FontSize="20" Margin="0,0,0,10"/>
                
                <CheckBox Name="ChkDefault" Content="Mặc định chọn cài đặt" IsChecked="True" FontWeight="Bold" Foreground="#2E7D32" Margin="0,0,0,10"/>
                
                <TextBlock Text="Tên hiển thị phần mềm:" FontSize="11" Foreground="#666"/>
                <TextBox Name="TxtName" Height="30" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>
                
                <TextBlock Text="Winget ID:" FontSize="11" Foreground="#666"/>
                <Grid Margin="0,5,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtWinget" Height="30" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                    <Button Name="BtnDowinget" Grid.Column="1" Content="🔍 Dò Winget" Background="#0288D1" Foreground="White" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <TextBlock Text="Choco ID:" FontSize="11" Foreground="#666"/>
                <Grid Margin="0,5,0,10">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
                    <TextBox Name="TxtChoco" Height="30" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                    <Button Name="BtnDoChoco" Grid.Column="1" Content="🪄 Dò Choco" Background="#9C27B0" Foreground="White" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <TextBlock Text="GDrive File ID:" FontSize="11" Foreground="#666"/>
                <TextBox Name="TxtGDrive" Height="30" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>

                <TextBlock Text="Silent Args (Lệnh cài ngầm):" FontSize="11" Foreground="#666"/>
                <TextBox Name="TxtSilent" Height="30" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>

                <TextBlock Text="Link Logo (Icon URL):" FontSize="11" Foreground="#E65100" FontWeight="Bold"/>
                <Grid Margin="0,5,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="100"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="TxtIcon" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                    <Button Name="BtnDoIcon" Grid.Column="1" Content="🖼️ Dò Icon" Background="#FB8C00" Foreground="White" FontWeight="Bold" Cursor="Hand">
                        <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="5"/></Style></Button.Resources>
                    </Button>
                </Grid>

                <Border Background="#FFF8E1" CornerRadius="10" BorderBrush="#FFCC80" BorderThickness="1" Height="110" Margin="0,0,0,15" Padding="10">
                    <StackPanel Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Center">
                        <Image Name="ImgPreview" Width="70" Height="70" Stretch="Uniform" ToolTip="Xem trước Logo phần mềm"/>
                        <TextBlock Name="TxtPreviewStatus" Text="Chưa có Logo" FontSize="12" Foreground="#FF9800" Margin="0,5,0,0" HorizontalAlignment="Center" FontWeight="SemiBold"/>
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
                
                <Button Name="BtnPush" Content="🚀 ĐẨY LÊN GITHUB CLOUD" Height="60" Background="#0D47A1" Foreground="White" FontSize="15" FontWeight="Bold" Cursor="Hand">
                     <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
                </Button>
                <TextBlock Name="TxtStatus" Text="Trạng thái: Đã sẵn sàng." FontSize="11" Foreground="#666" Margin="0,10,0,0" HorizontalAlignment="Center"/>
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
                                <DataTemplate>
                                    <Image Source="{Binding IconURL}" Width="24" Height="24"/>
                                </DataTemplate>
                            </DataGridTemplateColumn.CellTemplate>
                        </DataGridTemplateColumn>
                        <DataGridTextColumn Header="Tên Phần Mềm" Binding="{Binding Name}" Width="160"/>
                        <DataGridTextColumn Header="Winget ID" Binding="{Binding WingetID}" Width="130"/>
                        <DataGridTextColumn Header="Choco ID" Binding="{Binding ChocoID}" Width="110"/>
                    </DataGrid.Columns>
                </DataGrid>
                
                <UniformGrid Grid.Row="1" Columns="2" Height="35" Margin="0,15,0,0">
                    <Button Name="BtnClear" Content="🧹 TRỐNG Ô NHẬP" Background="#90A4AE" Foreground="White" FontWeight="Bold" Margin="0,0,5,0" Cursor="Hand"/>
                    <Button Name="BtnDel" Content="🗑️ XOÁ DÒNG" Background="#D32F2F" Foreground="White" FontWeight="Bold" Margin="5,0,0,0" Cursor="Hand"/>
                </UniformGrid>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $script:ListApp = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $dgList = $window.FindName("DgList"); $dgList.ItemsSource = $script:ListApp
    
    # Map controls
    $chk = $window.FindName("ChkDefault"); $tName = $window.FindName("TxtName"); $tWin = $window.FindName("TxtWinget")
    $tCho = $window.FindName("TxtChoco"); $tGDr = $window.FindName("TxtGDrive"); $tSil = $window.FindName("TxtSilent")
    $tIco = $window.FindName("TxtIcon"); $txtStatus = $window.FindName("TxtStatus")
    $imgPreview = $window.FindName("ImgPreview")
    $txtPreviewStatus = $window.FindName("TxtPreviewStatus")

    # --- SỰ KIỆN TỰ ĐỘNG LOAD PREVIEW ẢNH (BẢN THÔNG MINH) ---
    $tIco.Add_TextChanged({
        if ($tIco.Text -match "^http") {
            try {
                $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                $bmp.BeginInit()
                $bmp.UriSource = New-Object System.Uri($tIco.Text, [System.UriKind]::Absolute)
                $bmp.EndInit()
                $imgPreview.Source = $bmp
                $txtPreviewStatus.Visibility = "Collapsed" # Ẩn chữ đi khi có ảnh
            } catch { 
                $imgPreview.Source = $null 
                $txtPreviewStatus.Visibility = "Visible"
                $txtPreviewStatus.Text = "❌ Không tải được ảnh!"
                $txtPreviewStatus.Foreground = "Red"
            }
        } else {
            $imgPreview.Source = $null
            $txtPreviewStatus.Visibility = "Visible"
            $txtPreviewStatus.Text = "Chưa có Logo"
            $txtPreviewStatus.Foreground = "#FF9800"
        }
    })

    # --- HÀM TẢI DỮ LIỆU ---
    function Reload-Admin {
        $script:ListApp.Clear()
        try {
            $headers = @{"Authorization" = "token $Global:GH_TOKEN"; "Accept" = "application/vnd.github.v3+json"}
            $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get
            $csvText = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($response.content))
            $csvData = $csvText.Trim() | ConvertFrom-Csv
            
            foreach ($a in $csvData) {
                $icon = ""
                if ($a.PSObject.Properties.Match('IconURL').Count -gt 0) { $icon = $a.IconURL }
                $script:ListApp.Add([PSCustomObject]@{
                    Check = ($a.Check -match "True"); Name = $a.Name; WingetID = $a.WingetID; ChocoID = $a.ChocoID; GDriveID = $a.GDriveID; SilentArgs = $a.SilentArgs; IconURL = $icon
                })
            }
        } catch { }
    }

    # --- HÀM TÌM ICON ---
    function Show-IconPicker($appName) {
        $form = New-Object System.Windows.Forms.Form
        $form.Text = "Dò Logo cho $appName"; $form.Size = "450,180"; $form.StartPosition = "CenterParent"; $form.BackColor = "White"
        
        $lbl = New-Object System.Windows.Forms.Label; $lbl.Text = "Nhập trang chủ của phần mềm (VD: zalo.me, google.com):"; $lbl.Location = "20,20"; $lbl.AutoSize = $true; $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $txt = New-Object System.Windows.Forms.TextBox; $txt.Location = "20,50"; $txt.Size = "390,25"; $txt.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "TẠO LINK LOGO"; $btnOk.Location = "20,90"; $btnOk.Size = "150,35"; $btnOk.BackColor = "#FB8C00"; $btnOk.ForeColor = "White"; $btnOk.FlatStyle = "Flat"; $btnOk.DialogResult = "OK"
        
        $form.Controls.AddRange(@($lbl, $txt, $btnOk)); $form.AcceptButton = $btnOk
        
        if ($form.ShowDialog() -eq "OK" -and $txt.Text) {
            $domain = $txt.Text.Trim().Replace("https://", "").Replace("http://", "").Replace("www.", "").Split('/')[0]
            return "https://icon.horse/icon/$domain"
        }
        return $null
    }

    # --- CÁC HÀM DÒ ID WINGET/CHOCO (Giữ nguyên) ---
    function Show-WingetPicker($appName) {
        if (!(Get-Command winget -ErrorAction SilentlyContinue)) { return $null }
        $env:WINGET_DISABLE_PROGRESS = "true"
        $raw = (winget search "$appName" --accept-source-agreements 2>&1) -join "`n"
        $results = @(); $lines = $raw -split "`n"; $start = $false
        foreach ($line in $lines) {
            if ($line -match "^---") { $start = $true; continue }
            if ($start -and $line.Trim() -ne "") {
                if ($line -match '(?<Name>.+?)\s+(?<Id>[a-zA-Z0-9]+\.[a-zA-Z0-9\.]+)\s+(?<Version>\S+)') {
                    $results += [PSCustomObject]@{ Id = $matches['Id'].Trim(); Name = $matches['Name'].Trim() }
                }
            }
        }
        if ($results.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Không tìm thấy ID Winget!"); return $null }
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
        $searchTerm = $appName -replace '\s+', '' -replace '[^a-zA-Z0-9\-]', ''
        $results = choco search "$searchTerm" --limit-output | Select-Object -First 10
        $picker = New-Object System.Windows.Forms.Form; $picker.Text = "Chọn Choco ID"; $picker.Size = "400,320"; $picker.StartPosition = "CenterParent"
        $lb = New-Object System.Windows.Forms.ListBox; $lb.Dock = "Top"; $lb.Height = 200; $lb.Font = New-Object System.Drawing.Font("Segoe UI", 10)
        foreach ($res in $results) { if ($res -match "\|") { [void]$lb.Items.Add($res.Split("|")[0]) } }
        $btnOk = New-Object System.Windows.Forms.Button; $btnOk.Text = "OK"; $btnOk.Dock = "Bottom"; $btnOk.DialogResult = "OK"
        $picker.Controls.AddRange(@($lb, $btnOk))
        if ($picker.ShowDialog() -eq "OK" -and $lb.SelectedItem) { return $lb.SelectedItem.ToString() }
        return $null
    }

    # --- SỰ KIỆN GIAO DIỆN ---
    $dgList.Add_SelectionChanged({
        $selected = $dgList.SelectedItem
        if ($selected) {
            $chk.IsChecked = $selected.Check; $tName.Text = $selected.Name; $tWin.Text = $selected.WingetID
            $tCho.Text = $selected.ChocoID; $tGDr.Text = $selected.GDriveID; $tSil.Text = $selected.SilentArgs
            $tIco.Text = $selected.IconURL
        }
    })

    $window.FindName("BtnClear").Add_Click({
        $chk.IsChecked=$true; $tName.Text=""; $tWin.Text=""; $tCho.Text=""; $tGDr.Text=""; $tSil.Text=""; $tIco.Text=""
        $dgList.SelectedItem = $null
    })

    $window.FindName("BtnDowinget").Add_Click({ if ($tName.Text) { $id = Show-WingetPicker $tName.Text; if ($id) { $tWin.Text = $id } } })
    $window.FindName("BtnDoChoco").Add_Click({ if ($tName.Text) { $id = Show-ChocoPicker $tName.Text; if ($id) { $tCho.Text = $id } } })

    $window.FindName("BtnDoIcon").Add_Click({
        if ($tName.Text) { 
            $link = Show-IconPicker $tName.Text
            if ($link) { $tIco.Text = $link } 
        } else {
            [System.Windows.Forms.MessageBox]::Show("Hãy nhập Tên phần mềm trước!")
        }
    })

    $window.FindName("BtnAdd").Add_Click({
        if ($tName.Text) {
            $script:ListApp.Add([PSCustomObject]@{
                Check=$chk.IsChecked; Name=$tName.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text
            })
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    $window.FindName("BtnEdit").Add_Click({
        $idx = $dgList.SelectedIndex
        if ($idx -ge 0 -and $tName.Text) {
            $script:ListApp[$idx] = [PSCustomObject]@{
                Check=$chk.IsChecked; Name=$tName.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text
            }
        }
    })

    $window.FindName("BtnDel").Add_Click({
        if ($dgList.SelectedIndex -ge 0) {
            $script:ListApp.RemoveAt($dgList.SelectedIndex)
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    $window.FindName("BtnPush").Add_Click({
        try {
            $txtStatus.Text = "⏳ Đang đóng gói dữ liệu và kết nối GitHub..."
            
            # 1. Đóng gói dữ liệu CSV
            $csvStr = "Check,Name,WingetID,ChocoID,GDriveID,SilentArgs,IconURL`n"
            foreach ($item in $script:ListApp) {
                $cName = $item.Name -replace ',', '' # Xóa dấu phẩy chống lỗi CSV
                $csvStr += "$($item.Check),$cName,$($item.WingetID),$($item.ChocoID),$($item.GDriveID),$($item.SilentArgs),$($item.IconURL)`n"
            }
            
            $base64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($csvStr.Trim()))
            
            # 2. KHÔI PHỤC USER-AGENT (Giấy thông hành bắt buộc của GitHub)
            $headers = @{
                "Authorization" = "token $Global:GH_TOKEN"
                "Accept"        = "application/vnd.github.v3+json"
                "User-Agent"    = "VietToolbox"
            }
            
            # 3. Lấy mã SHA của file cũ (nếu có)
            $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction SilentlyContinue
            
            # 4. Gói dữ liệu JSON
            $body = @{ 
                message = "Cập nhật Danh Sách App V124.2 (Có Icon)"
                content = $base64
            }
            if ($info -and $info.sha) { $body.Add("sha", $info.sha) }
            
            $jsonBody = $body | ConvertTo-Json -Compress

            # 5. Gửi lên GitHub
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $jsonBody -ContentType "application/json"
            
            $txtStatus.Text = "✅ Đã cập nhật lên GitHub Cloud thành công!"
            [System.Windows.Forms.MessageBox]::Show("Tuyệt vời! Đã đẩy dữ liệu lên GitHub thành công. Bạn có thể mở Client để kiểm tra.", "Thành Công", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            
            Reload-Admin
        } catch { 
            $errMsg = $_.Exception.Message
            if ($_.Exception.Response) {
                try {
                    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                    $errMsg += "`nChi tiết: " + $reader.ReadToEnd()
                    $reader.Close()
                } catch { }
            }
            $txtStatus.Text = "❌ Lỗi: Cập nhật thất bại!"
            [System.Windows.Forms.MessageBox]::Show("Lỗi đẩy dữ liệu lên Cloud:`n`n$errMsg", "Lỗi Cập Nhật", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })

    Reload-Admin; $window.ShowDialog() | Out-Null
}

&$LogicVietToolboxCloudV124