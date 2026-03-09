# 1. ÉP HỆ THỐNG DÙNG TLS 1.2 & UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

$LogicDoiSoVND = {
    $xlStartPath = "$env:APPDATA\Microsoft\Excel\XLSTART"
    $addinName   = "VietToolbox_VND_DaNang.xlam"
    $targetFile  = Join-Path $xlStartPath $addinName

    function Set-ExcelTrust {
        param([int]$value)
        $versions = @("14.0", "15.0", "16.0")
        foreach ($ver in $versions) {
            $regPath = "HKCU:\Software\Microsoft\Office\$ver\Excel\Security"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "AccessVBOM" -Value $value -ErrorAction SilentlyContinue
            }
        }
    }

    # --- GIAO DIỆN ---
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VIETTOOLBOX - ĐỔI SỐ THÀNH CHỮ"; $form.Size = "500,420"; $form.BackColor = "White"; $form.StartPosition = "CenterScreen"
    
    $lblTitle = New-Object System.Windows.Forms.Label; $lblTitle.Text = "CÀI ĐẶT HÀM =VND() ĐA NĂNG"; $lblTitle.Location = "20,30"; $lblTitle.Size = "450,30"; $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI Semibold", 12); $lblTitle.ForeColor = "#2E7D32"
    $lblDesc = New-Object System.Windows.Forms.Label; $lblDesc.Text = "Sử dụng hàm =VND(ô_tính). Tự động nhận diện VNĐ, USD, EUR... dựa trên ký hiệu trong ô."; $lblDesc.Location = "20,70"; $lblDesc.Size = "440,60"; $lblDesc.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    
    $btnInstall = New-Object System.Windows.Forms.Button; $btnInstall.Text = "CÀI ĐẶT HÀM"; $btnInstall.Location = "50,150"; $btnInstall.Size = "180,65"; $btnInstall.BackColor = "#4CAF50"; $btnInstall.ForeColor = "White"; $btnInstall.FlatStyle = "Flat"; $btnInstall.Font = New-Object System.Drawing.Font("Segoe UI Bold", 10)
    $btnUninstall = New-Object System.Windows.Forms.Button; $btnUninstall.Text = "GỠ BỎ HÀM"; $btnUninstall.Location = "250,150"; $btnUninstall.Size = "180,65"; $btnUninstall.BackColor = "#F44336"; $btnUninstall.ForeColor = "White"; $btnUninstall.FlatStyle = "Flat"; $btnUninstall.Font = New-Object System.Drawing.Font("Segoe UI Bold", 10)

    $lblStatus = New-Object System.Windows.Forms.Label; $lblStatus.Text = "Trạng thái: Sẵn sàng..."; $lblStatus.Location = "20,260"; $lblStatus.Size = "450,20"; $lblStatus.ForeColor = "Gray"
    $form.Controls.AddRange(@($lblTitle, $lblDesc, $btnInstall, $btnUninstall, $lblStatus))

    # --- NỘI DUNG CODE VBA (ĐÃ ĐỔI TÊN THÀNH VND) ---
    $vbaCode = @'
Function VND(ByVal Target As Variant) As String
    Dim ValText As String, CurrencyPart As String
    Dim OnlyNum As Double, i As Integer
    Dim Chuso, DonviLon, Result As String, Group As String, Temp As String
    
    If IsEmpty(Target) Or Trim(CStr(Target)) = "" Then: VND = "": Exit Function
    
    ValText = LCase(Trim(CStr(Target)))
    
    ' Nhận diện ngoại tệ
    If InStr(ValText, "$") > 0 Or InStr(ValText, "usd") > 0 Then
        CurrencyPart = " " & ChrW(273) & ChrW(244) & " la M" & ChrW(7929)
    ElseIf InStr(ValText, ChrW(8364)) > 0 Or InStr(ValText, "eur") > 0 Then
        CurrencyPart = " Euro"
    ElseIf InStr(ValText, "cny") > 0 Then
        CurrencyPart = " Nh" & ChrW(226) & "n d" & ChrW(226) & "n t" & ChrW(7879)
    Else
        CurrencyPart = " " & ChrW(273) & ChrW(7891) & "ng"
    End If

    ' Trích xuất số
    Dim CleanNum As String: CleanNum = ""
    For i = 1 To Len(ValText)
        Dim c As String: c = Mid(ValText, i, 1)
        If IsNumeric(c) Or c = "." Or c = "," Then
            If c = "," Then c = "."
            CleanNum = CleanNum & c
        End If
    Next i
    
    If CleanNum = "" Then: VND = "": Exit Function
    OnlyNum = Val(CleanNum)
    If OnlyNum = 0 Then: VND = "": Exit Function
    
    Chuso = Array("", "m" & ChrW(7897) & "t ", "hai ", "ba ", "b" & ChrW(7889) & "n ", "n" & ChrW(259) & "m ", "s" & ChrW(225) & "u ", "b" & ChrW(7843) & "y ", "t" & ChrW(225) & "m ", "ch" & ChrW(237) & "n ")
    DonviLon = Array("", "ngh" & ChrW(236) & "n ", "tri" & ChrW(7879) & "u ", "t" & ChrW(7927) & " ", "ngh" & ChrW(236) & "n t" & ChrW(7927) & " ", "tri" & ChrW(7879) & "u t" & ChrW(7927) & " ")
    
    Dim sNumber As String
    sNumber = Format(Abs(Round(OnlyNum, 0)), "################")
    sNumber = Right(String(18, "0") & sNumber, 18)
    
    For i = 1 To 6
        Group = Mid(sNumber, (i - 1) * 3 + 1, 3)
        If Group <> "000" Then
            Temp = ""
            If Mid(Group, 1, 1) <> "0" Then
                Temp = Chuso(Mid(Group, 1, 1)) & "tr" & ChrW(259) & "m "
            ElseIf Result <> "" Then
                Temp = "kh" & ChrW(244) & "ng tr" & ChrW(259) & "m "
            End If
            
            Select Case Mid(Group, 2, 1)
                Case "0": If Temp <> "" And Mid(Group, 3, 1) <> "0" Then Temp = Temp & "l" & ChrW(7867) & " "
                Case "1": Temp = Temp & "m" & ChrW(432) & ChrW(7901) & "i "
                Case Else: Temp = Temp & Chuso(Mid(Group, 2, 1)) & "m" & ChrW(432) & ChrW(417) & "i "
            End Select
            
            Select Case Mid(Group, 3, 1)
                Case "0"
                Case "1": If Mid(Group, 2, 1) <> "0" And Mid(Group, 2, 1) <> "1" Then Temp = Temp & "m" & ChrW(7889) & "t " Else Temp = Temp & "m" & ChrW(7897) & "t "
                Case "5": If Mid(Group, 2, 1) <> "0" Then Temp = Temp & "l" & ChrW(259) & "m " Else Temp = Temp & "n" & ChrW(259) & "m "
                Case Else: Temp = Temp & Chuso(Mid(Group, 3, 1))
            End Select
            Result = Result & Temp & DonviLon(6 - i)
        End If
    Next i
    
    Result = Trim(Result)
    VND = UCase(Left(Result, 1)) & Mid(Result, 2) & CurrencyPart
End Function
'@

    $btnInstall.Add_Click({
        try {
            Set-ExcelTrust 1
            Get-Process excel -ErrorAction SilentlyContinue | Stop-Process -Force
            if (!(Test-Path $xlStartPath)) { New-Object -ItemType Directory -Path $xlStartPath -Force }
            
            $Excel = New-Object -ComObject Excel.Application
            $Excel.Visible = $false
            $Workbook = $Excel.Workbooks.Add()
            $Module = $Workbook.VBProject.VBComponents.Add(1)
            $Module.CodeModule.AddFromString($vbaCode)
            $Workbook.SaveAs($targetFile, 55)
            $Workbook.Close($false)
            $Excel.Quit()
            
            [System.Windows.Forms.MessageBox]::Show("Đã cài đặt thành công hàm =VND()!", "VietToolbox")
            $lblStatus.Text = "Hoàn tất."
        } catch { [System.Windows.Forms.MessageBox]::Show("Lỗi: " + $_.Exception.Message) }
    })

    $btnUninstall.Add_Click({
        Get-Process excel -ErrorAction SilentlyContinue | Stop-Process -Force
        if (Test-Path $targetFile) { Remove-Item $targetFile -Force; [System.Windows.Forms.MessageBox]::Show("Đã gỡ bỏ!") }
    })

    $form.ShowDialog() | Out-Null
}

&$LogicDoiSoVND