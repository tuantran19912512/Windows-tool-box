# ==============================================================================
# VIETTOOLBOX ADMIN V125 - BẢN WPF HIỆN ĐẠI (FIX LỖI 400 TRIỆT ĐỂ)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# Đặc trị: Giao diện Modern 2 Cột + Dò Icon + Build JSON Thủ Công Fix Lỗi 400
# ==============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

$LogicVietToolboxCloudV125 = {
    if (-not $Global:GH_TOKEN) {
        [System.Windows.Forms.MessageBox]::Show("Thiếu GitHub Token ở Main! Hãy đăng nhập trước.", "Lỗi hệ thống")
        return
    }

    $GH_USER  = "tuantran19912512"
    $GH_REPO  = "Windows-tool-box"
    $GH_FILE  = "DanhSachPhanMem.csv"
    $apiUrl   = "https://api.github.com/repos/$GH_USER/$GH_REPO/contents/$GH_FILE"

    # --- GIAO DIỆN WPF HIỆN ĐẠI CHIA 2 CỘT ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VietToolbox Admin V125" Width="1150" Height="820" WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <WindowChrome.WindowChrome><WindowChrome GlassFrameThickness="0" CornerRadius="15" CaptionHeight="35" ResizeBorderThickness="7" /></WindowChrome.WindowChrome>
    <Border Background="#F4F7F9" CornerRadius="15" BorderBrush="#0D47A1" BorderThickness="1.5">
        <Grid Margin="20">
            <Grid.RowDefinitions><RowDefinition Height="35"/><RowDefinition Height="*"/></Grid.RowDefinitions>
            
            <Grid Name="TitleBar" Grid.Row="0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="Auto"/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                <TextBlock Text="VietToolbox Admin V125 - Cloud Manager" Foreground="#888" VerticalAlignment="Center" Margin="5,0,0,0" FontWeight="Bold"/>
                <Button Name="btnMinimize" Grid.Column="1" Content="—" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand"/><Button Name="btnClose" Grid.Column="2" Content="✕" Width="40" Background="Transparent" BorderThickness="0" Cursor="Hand" Foreground="#D32F2F" FontWeight="Bold"/>
            </Grid>

            <Grid Grid.Row="1" Margin="0,10,0,0">
                <Grid.ColumnDefinitions><ColumnDefinition Width="380"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
                
                <Border Grid.Column="0" Background="White" CornerRadius="12" Padding="20" Margin="0,0,15,0" BorderBrush="#E0E0E0" BorderThickness="1">
                    <StackPanel>
                        <TextBlock Text="QUẢN TRỊ PHẦN MỀM" FontWeight="Bold" Foreground="#1A237E" FontSize="22" Margin="0,0,0,10" HorizontalAlignment="Center"/>
                        <CheckBox Name="ChkDefault" Content="Mặc định chọn cài đặt" IsChecked="True" FontWeight="Bold" Foreground="#2E7D32" Margin="0,0,0,15"/>
                        
                        <TextBlock Text="Tên hiển thị:" FontSize="12" Foreground="#666"/>
                        <TextBox Name="TxtName" Height="32" Margin="0,5,0,10" VerticalContentAlignment="Center" Padding="5,0"/>
                        
                        <TextBlock Text="Winget ID:" FontSize="12" Foreground="#666"/>
                        <Grid Margin="0,5,0,10">
                            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="90"/></Grid.ColumnDefinitions>
                            <TextBox Name="TxtWinget" Height="32" VerticalContentAlignment="Center" Padding="5,0" Margin="0,0,5,0"/>
                            <Button Name="BtnDowinget" Grid.Column="1" Content="🔍 Dò Winget" Background="#0288D1" Foreground="White" FontWeight="Bold" Cursor="Hand">
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

                        <TextBlock Text="GDrive ID:" FontSize="12" Foreground="#666"/>
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

                        <UniformGrid Columns="2" Height="45" Margin="0,0,0,20">
                            <Button Name="BtnAdd" Content="➕ THÊM MỚI" Background="#2E7D32" Foreground="White" FontWeight="Bold" Margin="0,0,5,0" Cursor="Hand">
                                 <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                            <Button Name="BtnEdit" Content="📝 LƯU SỬA" Background="#1565C0" Foreground="White" FontWeight="Bold" Margin="5,0,0,0" Cursor="Hand">
                                 <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></Button.Resources>
                            </Button>
                        </UniformGrid>

                        <Button Name="BtnPush" Content="🚀 LƯU ĐỒNG BỘ LÊN GITHUB" Height="65" Background="#0D47A1" Foreground="White" FontSize="15" FontWeight="Bold" Cursor="Hand">
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
                                <DataGridTextColumn Header="Tên Phần Mềm" Binding="{Binding Name}" Width="160"/>
                                <DataGridTextColumn Header="Winget ID" Binding="{Binding WingetID}" Width="140"/>
                                <DataGridTextColumn Header="Choco ID" Binding="{Binding ChocoID}" Width="120"/>
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
    $tCho = $window.FindName("TxtChoco"); $tGDr = $window.FindName("TxtGDrive"); $tSil = $window.FindName("TxtSilent")
    $tIco = $window.FindName("TxtIcon"); $txtStatus = $window.FindName("TxtStatus")
    $imgPreview = $window.FindName("ImgPreview"); $txtPreviewStatus = $window.FindName("TxtPreviewStatus")

    $window.FindName("TitleBar").Add_MouseLeftButtonDown({ $window.DragMove() })
    $window.FindName("btnMinimize").Add_Click({ $window.WindowState = "Minimized" })
    $window.FindName("btnClose").Add_Click({ $window.Close() })

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
                $script:ListApp.Add([PSCustomObject]@{ Check = ($a.Check -match "True"); Name = $a.Name; WingetID = $a.WingetID; ChocoID = $a.ChocoID; GDriveID = $a.GDriveID; SilentArgs = $a.SilentArgs; IconURL = $icon })
            }
        } catch { }
    }

    # --- CÁC HÀM DÒ TÌM ---
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

    # --- SỰ KIỆN NÚT BẤM ---
    $dgList.Add_SelectionChanged({
        if ($dgList.SelectedItem) {
            $chk.IsChecked = $dgList.SelectedItem.Check; $tName.Text = $dgList.SelectedItem.Name; $tWin.Text = $dgList.SelectedItem.WingetID
            $tCho.Text = $dgList.SelectedItem.ChocoID; $tGDr.Text = $dgList.SelectedItem.GDriveID; $tSil.Text = $dgList.SelectedItem.SilentArgs; $tIco.Text = $dgList.SelectedItem.IconURL
        }
    })

    $window.FindName("BtnClear").Add_Click({ $chk.IsChecked=$true; $tName.Text=""; $tWin.Text=""; $tCho.Text=""; $tGDr.Text=""; $tSil.Text=""; $tIco.Text=""; $dgList.SelectedItem = $null })
    $window.FindName("BtnDowinget").Add_Click({ if ($tName.Text) { $id = Show-WingetPicker $tName.Text; if ($id) { $tWin.Text = $id } } })
    $window.FindName("BtnDoChoco").Add_Click({ if ($tName.Text) { $id = Show-ChocoPicker $tName.Text; if ($id) { $tCho.Text = $id } } })
    $window.FindName("BtnDoIcon").Add_Click({ if ($tName.Text) { $link = Show-IconPicker $tName.Text; if ($link) { $tIco.Text = $link } } else { [System.Windows.Forms.MessageBox]::Show("Nhập Tên phần mềm trước!") } })

    $window.FindName("BtnAdd").Add_Click({
        if ($tName.Text) {
            $script:ListApp.Add([PSCustomObject]@{ Check=$chk.IsChecked; Name=$tName.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text })
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    $window.FindName("BtnEdit").Add_Click({
        $idx = $dgList.SelectedIndex
        if ($idx -ge 0 -and $tName.Text) {
            $script:ListApp[$idx] = [PSCustomObject]@{ Check=$chk.IsChecked; Name=$tName.Text; WingetID=$tWin.Text; ChocoID=$tCho.Text; GDriveID=$tGDr.Text; SilentArgs=$tSil.Text; IconURL=$tIco.Text }
        }
    })

    $window.FindName("BtnDel").Add_Click({
        if ($dgList.SelectedIndex -ge 0) {
            $script:ListApp.RemoveAt($dgList.SelectedIndex)
            $window.FindName("BtnClear").RaiseEvent((New-Object System.Windows.RoutedEventArgs([System.Windows.Controls.Primitives.ButtonBase]::ClickEvent)))
        }
    })

    # --- ĐẠI PHẪU NÚT PUSH: FIX LỖI 400 BẰNG JSON THỦ CÔNG ---
    $window.FindName("BtnPush").Add_Click({
        try {
            $txtStatus.Text = "⏳ Đang kết nối..."
            
            # 1. Tạo CSV chuẩn và dọn dẹp các ký tự dị biệt
            $csvStr = "Check,Name,WingetID,ChocoID,GDriveID,SilentArgs,IconURL`n"
            foreach ($item in $script:ListApp) {
                $cName = $item.Name -replace ',', ' ' -replace '"', ''
                $csvStr += "$($item.Check),$cName,$($item.WingetID),$($item.ChocoID),$($item.GDriveID),$($item.SilentArgs),$($item.IconURL)`n"
            }
            
            # 2. Sinh mã Base64 cực kỳ tinh khiết (Xóa mọi dấu ngắt dòng)
            $bytes = [System.Text.Encoding]::UTF8.GetBytes($csvStr.Trim())
            $base64 = [System.Convert]::ToBase64String($bytes) -replace "`r", "" -replace "`n", ""
            
            # 3. Headers chuẩn của GitHub
            $headers = @{
                "Authorization" = "token $Global:GH_TOKEN"
                "Accept"        = "application/vnd.github.v3+json"
                "User-Agent"    = "VietToolbox"
            }
            
            # 4. Lấy mã SHA cũ để GitHub cho phép ghi đè
            $sha = ""
            try { 
                $info = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get -ErrorAction Stop 
                if ($info.sha) { $sha = $info.sha }
            } catch { }
            
            # 5. TỰ VIẾT CHUỖI JSON (Cách mạng hóa: Bỏ qua lỗi của hàm ConvertTo-Json)
            if ($sha -eq "") {
                $jsonBody = '{"message":"Cập nhật phần mềm mới","content":"' + $base64 + '"}'
            } else {
                $jsonBody = '{"message":"Cập nhật phần mềm mới","content":"' + $base64 + '","sha":"' + $sha + '"}'
            }

            # 6. Gửi lệnh (Bắt buộc khai báo utf-8)
            Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Put -Body $jsonBody -ContentType "application/json; charset=utf-8"
            
            $txtStatus.Text = "✅ Thành công!"
            [System.Windows.Forms.MessageBox]::Show("Đã lưu dữ liệu lên Cloud thành công tuyệt đối!", "Xong", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            Reload-Admin
        } catch { 
            # Bắt lỗi 400 và soi tận gốc
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

&$LogicVietToolboxCloudV125