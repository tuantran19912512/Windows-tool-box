# ==========================================================
# VIETTOOLBOX - GỠ OFFICE & DỌN TẬN GỐC V2.2 (PURE WPF EDITION)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# 1. ÉP CHẠY QUYỀN ADMINISTRATOR
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. THIẾT LẬP MÔI TRƯỜNG & NẠP WPF
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicGoOfficeV22 = {
    # --- 3. KHỞI TẠO GIAO DIỆN XAML ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - GỠ OFFICE &amp; DỌN TẬN GỐC V2.2" Width="800" Height="650"
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.6"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="CÔNG CỤ GỠ CÀI ĐẶT MICROSOFT OFFICE / 365" FontSize="22" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Hỗ trợ gỡ sạch sẽ các bản Office MSI và Click-to-Run cứng đầu" Foreground="#666666"/>
        </StackPanel>

        <ListView Name="lvOffice" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" BorderThickness="1" Margin="0,0,0,15">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="40">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><CheckBox IsChecked="{Binding IsChecked}"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="CÁC BẢN OFFICE TRÊN MÁY" DisplayMemberBinding="{Binding Name}" Width="480"/>
                    <GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding Status}" Width="180"/>
                </GridView>
            </ListView.View>
        </ListView>

        <StackPanel Grid.Row="2" Margin="0,0,0,20">
            <TextBlock Name="lblStatus" Text="Sẵn sàng..." FontStyle="Italic" Foreground="#333333" Margin="0,0,0,5"/>
            <ProgressBar Name="pgBar" Height="25" Background="#E0E0E0" Foreground="#1565C0" BorderThickness="0"/>
        </StackPanel>

        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="150"/>
                <ColumnDefinition Width="15"/>
                <ColumnDefinition Width="250"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            
            <Button Name="btnRefresh" Grid.Column="0" Content="LÀM MỚI" Height="60" Background="#455A64" Foreground="White" FontWeight="Bold"/>
            
            <Button Name="btnCleanAll" Grid.Column="2" Content="DỌN SẠCH TẬN GỐC" Height="60" Background="#FF8F00" Foreground="White" FontWeight="Bold" FontSize="14" Visibility="Collapsed"/>
            
            <Button Name="btnUninstall" Grid.Column="3" Content="BẮT ĐẦU GỠ" Height="60" Background="#D32F2F" Foreground="White" FontWeight="Bold" FontSize="16"/>
        </Grid>
    </Grid>
</Window>
"@

    # --- 4. ÁNH XẠ GIAO DIỆN & BIẾN WPF ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $window = [Windows.Markup.XamlReader]::Load($DocXml)

    $lvOffice = $window.FindName("lvOffice")
    $lblStatus = $window.FindName("lblStatus")
    $pgBar = $window.FindName("pgBar")
    $btnRefresh = $window.FindName("btnRefresh")
    $btnCleanAll = $window.FindName("btnCleanAll")
    $btnUninstall = $window.FindName("btnUninstall")

    # Tạo danh sách liên kết cho ListView
    $Global:OfficeList = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $lvOffice.ItemsSource = $Global:OfficeList

    # Hàm DoEvents tự chế cho WPF để chống đơ giao diện
    $CapNhatGiaoDien = {
        $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }

    # --- 5. HÀM QUÉT OFFICE ---
    function Get-OfficeList {
        $Global:OfficeList.Clear()
        $lblStatus.Text = "Đang quét sâu vào hệ thống..."
        &$CapNhatGiaoDien
        
        $paths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*", 
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
            "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\REGISTRY\MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
        )
        
        $officeApps = Get-ItemProperty $paths -ErrorAction SilentlyContinue | Where-Object { 
            ($_.DisplayName -match "Microsoft Office" -or $_.DisplayName -match "Microsoft 365") -and 
            ($_.UninstallString -ne $null -or $_.QuietUninstallString -ne $null)
        }
        
        $officeApps = $officeApps | Sort-Object DisplayName -Unique

        foreach ($app in $officeApps) {
            $uninstCmd = if ($app.QuietUninstallString) { $app.QuietUninstallString } else { $app.UninstallString }
            
            $Global:OfficeList.Add([PSCustomObject]@{
                IsChecked = $false
                Name = $app.DisplayName
                Status = "Sẵn sàng gỡ"
                Cmd = $uninstCmd
            })
        }
        
        if ($Global:OfficeList.Count -eq 0) {
            $lblStatus.Text = "Máy sạch sẽ! Không tìm thấy bản Office/365 nào."
        } else {
            $lblStatus.Text = "Tìm thấy $($Global:OfficeList.Count) bản Office/Microsoft 365."
        }
        $window.Dispatcher.Invoke([action]{ $lvOffice.Items.Refresh() })
    }

    # --- 6. HÀM DỌN DẸP TẬN GỐC ---
    $btnCleanAll.Add_Click({
        $msg = "Bạn có muốn xóa sạch Registry và Folder rác của Office?`n(Thao tác này giúp máy sạch 100% để cài bản mới không bị lỗi)"
        $hoiDap = [System.Windows.MessageBox]::Show($msg, "Xác nhận dọn dẹp", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($hoiDap -ne "Yes") { return }
        
        $btnCleanAll.IsEnabled = $false; $pgBar.IsIndeterminate = $true
        
        $regPaths = @("HKLM:\SOFTWARE\Microsoft\Office","HKCU:\Software\Microsoft\Office","HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office","HKLM:\SOFTWARE\Microsoft\AppVISV","HKCU:\Software\Microsoft\AppVISV")
        $folderPaths = @("$env:AppData\Microsoft\Office","$env:LocalAppData\Microsoft\Office","C:\Program Files\Microsoft Office","C:\Program Files (x86)\Microsoft Office")

        foreach ($p in $regPaths) { 
            if (Test-Path $p) { 
                $lblStatus.Text = "Xóa Registry: $p"; &$CapNhatGiaoDien
                Remove-Item -Path $p -Recurse -Force -ErrorAction SilentlyContinue 
            } 
        }
        foreach ($f in $folderPaths) { 
            if (Test-Path $f) { 
                $lblStatus.Text = "Xóa Folder: $f"; &$CapNhatGiaoDien
                Remove-Item -Path $f -Recurse -Force -ErrorAction SilentlyContinue 
            } 
        }

        $pgBar.IsIndeterminate = $false; $pgBar.Value = 100
        $lblStatus.Text = "Đã dọn sạch tuyệt đối!"
        $btnCleanAll.IsEnabled = $true
        [System.Windows.MessageBox]::Show("Đã quét sạch dấu vết Office!", "Thành công", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information)
    })

    # --- 7. SỰ KIỆN GỠ BỎ ---
    $btnUninstall.Add_Click({
        # Lọc ra các mục đã được người dùng tick Checkbox
        $itemsToUninstall = $Global:OfficeList | Where-Object { $_.IsChecked -eq $true }
        
        if ($itemsToUninstall.Count -eq 0) { 
            [System.Windows.MessageBox]::Show("Tuấn vui lòng tick chọn ít nhất 1 bản Office để gỡ!", "Nhắc nhở", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
            return 
        }

        $btnUninstall.IsEnabled = $false
        
        foreach ($item in $itemsToUninstall) {
            $item.Status = "⏳ Đang gỡ..."
            $lblStatus.Text = "Đang gỡ: $($item.Name)"
            $window.Dispatcher.Invoke([action]{ $lvOffice.Items.Refresh() })
            &$CapNhatGiaoDien

            try {
                $cmd = $item.Cmd
                if ($cmd -like "MsiExec.exe*") { 
                    $silent = ($cmd -replace "/I", "/X") + " /quiet /norestart"
                    Start-Process cmd.exe -ArgumentList "/c $silent" -Wait 
                } else { 
                    Start-Process cmd.exe -ArgumentList "/c $cmd" -Wait 
                }
                $item.Status = "✅ Đã gỡ"
            } catch { 
                $item.Status = "❌ Lỗi" 
            }
            $window.Dispatcher.Invoke([action]{ $lvOffice.Items.Refresh() })
        }
        
        $btnUninstall.IsEnabled = $true
        $lblStatus.Text = "Hoàn tất gỡ cài đặt!"
        $pgBar.Value = 100
        
        # --- QUAN TRỌNG: HIỆN NÚT DỌN SẠCH (WPF Visibility) ---
        $btnCleanAll.Visibility = "Visible"
        $lblStatus.Text = "Gợi ý: Hãy bấm 'DỌN SẠCH TẬN GỐC' để máy sạch 100%!"
    })

    $btnRefresh.Add_Click({ 
        Get-OfficeList
        $btnCleanAll.Visibility = "Collapsed" # Làm mới thì ẩn lại
        $pgBar.Value = 0
    }) 

    $window.Add_ContentRendered({ Get-OfficeList })
    $window.ShowDialog() | Out-Null
}

&$LogicGoOfficeV22