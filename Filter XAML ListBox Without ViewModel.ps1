#region dependencies
Add-Type -AssemblyName PresentationCore, PresentationFramework
#endregion

$Sync = [HashTable]::Synchronized(@{})

#region gui
[Xml]$WpfXml = @"
<Window x:Name="TextFilter" x:Class="WpfApp1.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:WpfApp1"
        mc:Ignorable="d"
        Title="Text filter" Visibility="Visible" Height="500" Width="900">
        <Window.Resources>
        <Style x:Key="DarkGrey" TargetType="FrameworkElement">
            <Setter Property="Control.Background" Value="#111111" />
            <Setter Property="Control.BorderBrush" Value="Black" />
        </Style>
        <Style x:Key="Dark" TargetType="FrameworkElement">
            <Setter Property="Control.Background" Value="Black" />
            <Setter Property="Control.BorderBrush" Value="Black" />
        </Style>
        <Style TargetType="Label" BasedOn="{StaticResource DarkGrey}">
            <Setter Property="Control.Foreground" Value="Silver" />
        </Style>
        <Style TargetType="TextBlock" BasedOn="{StaticResource DarkGrey}">
            <Setter Property="Control.Foreground" Value="Silver" />
        </Style>
        <Style TargetType="ListBox" BasedOn="{StaticResource Dark}">
            <Setter Property="Control.Foreground" Value="Silver" />
        </Style>
        <Style TargetType="Button">
            <Setter Property="Control.Background" Value="#222222" />
            <Setter Property="Control.Foreground" Value="Silver" />
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Control.Background" Value="#222222" />
            <Setter Property="Control.Foreground" Value="Silver" />
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Control.Foreground" Value="#AAAAAA" />
        </Style>
        <Style TargetType="{x:Type RadioButton}">
            <Setter Property="Control.Foreground" Value="#AAAAAA" />
        </Style>
        <Style TargetType="GroupBox" BasedOn="{StaticResource Dark}">
            <Setter Property="Control.Foreground" Value="#AAAAAA" />
        </Style>
        <Style TargetType="Menu" BasedOn="{StaticResource DarkGrey}"/>
        <Style TargetType="MenuItem">
            <Setter Property="Control.Foreground" Value="Silver" />
            <Setter Property="Control.Background" Value="#111111" />
            <Style.Triggers>
                <Trigger Property="IsHighlighted" Value="True">
                    <Setter Property="Control.Background" Value="Yellow" />
                </Trigger>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Control.Background" Value="Yellow" />
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="Window" BasedOn="{StaticResource DarkGrey}">
        </Style>
    </Window.Resources>
    <DockPanel>
        <Menu DockPanel.Dock="Top">
            <MenuItem Header="_Menu">
                <Separator />
            </MenuItem>
        </Menu>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="23"/>
                <RowDefinition Height="50"/>
                <RowDefinition/>
            </Grid.RowDefinitions>
            <Grid
                Grid.Row="0">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="35"/>
                    <ColumnDefinition/>
                </Grid.ColumnDefinitions>
                <TextBlock
                    Grid.Column="0"
                    Text="Input:"/>
                <TextBox
                    Grid.Column="1"
                    x:Name="txtFilter">
                    <TextBox.ContextMenu>
                        <ContextMenu>
                            <MenuItem
                                x:Name="mnuFilterCut"
                                Header="Cut"/>
                            <MenuItem
                                x:Name="mnuFilterCopy"
                                Header="Copy"/>
                            <MenuItem
                                x:Name="mnuFilterPaste"
                                Header="Paste"/>
                            <Separator/>
                            <MenuItem
                                x:Name="mnuFilterClear"
                                Header="Clear"/>
                                <MenuItem
                                x:Name="mnuFilterClearPaste"
                                Header="Clear and paste"/>
                        </ContextMenu>
                    </TextBox.ContextMenu>
                </TextBox>
                <TextBlock
                    Grid.Column="1"
                    Margin="-25,0,25,0"
                    x:Name="txtFilterClear"
                    Text="X"
                    HorizontalAlignment="Right"
                    VerticalAlignment="Center"
                    Visibility="Hidden"/>
            </Grid>
            <Grid
                Grid.Row="1">
                    <GroupBox
                        Header="Filter by"
                        Width="300"
                        HorizontalAlignment="Center">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition/>
                                <ColumnDefinition/>
                            </Grid.ColumnDefinitions>
                            <RadioButton
                                Grid.Column="0"
                                x:Name="rdoKeyword"
                                GroupName="FilterType"
                                IsChecked="True"
                                Content="Keyword"/>
                            <RadioButton
                                Grid.Column="1"
                                x:Name="rdoRegex"
                                GroupName="FilterType"
                                Content="Regex"/>
                        </Grid>
                    </GroupBox>
            </Grid>
            <ListBox
                Grid.Row="2"
                x:Name="lstFiles">
                <ListBox.ContextMenu>
                    <ContextMenu>
                    <MenuItem
                        x:Name="mnuListFileOpen"
                        Header="Open" />
                    <MenuItem
                        x:Name="mnuListCopy"
                        Header="Copy" />
                    </ContextMenu>
                </ListBox.ContextMenu>
            </ListBox>
        </Grid>
    </DockPanel>
</Window>
"@

$WpfXml.Window.RemoveAttribute('x:Class')
$WpfXml.Window.RemoveAttribute('mc:Ignorable')

$WpfNs = New-Object -TypeName Xml.XmlNamespaceManager -ArgumentList $WpfXml.NameTable
$WpfNs.AddNamespace('x', $WpfXml.DocumentElement.x)
$WpfNs.AddNamespace('d', $WpfXml.DocumentElement.d)
$WpfNs.AddNamespace('mc', $WpfXml.DocumentElement.mc)

$Sync.Gui = @{}

try {
    $Sync.Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $WpfXml))
} catch {
    Write-Host $_ -ForegroundColor Red
    Exit
}

$WpfXml.SelectNodes('//*[@x:Name]', $WpfNs) | ForEach-Object {
    $Sync.Gui.Add($_.Name, $Sync.Window.FindName($_.Name))
}
#endregion

#region init list items
[Array]$DataSource = Get-ChildItem * -LiteralPath $env:ProgramFiles -Directory
$Sync.Gui.lstFiles.ItemsSource = $DataSource

# set list filter
[System.Windows.Data.CollectionViewSource]::GetDefaultView($Sync.Gui.lstFiles.ItemsSource).Filter = {
    param($obj)
    if ($Sync.Gui.rdoKeyword.IsChecked) {
        return ($obj -like "*$($Sync.Gui.txtFilter.Text.Replace(" ","*").Replace("-","*"))*")
    } else {
        try {
            $RX = $Sync.Gui.txtFilter.Text
            $RX = [regex]::new($RX,([regex]$RX).Options -bor [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            return ($obj -match $RX)
        } catch {
            return ($obj -match ([Regex][Regex]::Escape($Sync.Gui.txtFilter.Text)))
        }
    }
}
#endregion

#region Form element event handlers
$Sync.Gui.txtFilter.add_TextChanged({
    [System.Windows.Data.CollectionViewSource]::GetDefaultView($Sync.Gui.lstFiles.ItemsSource).Refresh()
    $Sync.Gui.txtFilterClear.Visibility = if ($Sync.Gui.txtFilter.Text.Length -gt 0) {"Visible"} else {"Hidden"}
})

$Sync.Gui.txtFilterClear.add_PreviewMouseDown({
    if ($_.LeftButton -eq "Pressed") {
        $Sync.Gui.txtFilter.Text = [string]::Empty
    }
})

$Sync.Gui.mnuListFileOpen.add_Click({
    Invoke-Item -LiteralPath $Sync.Gui.lstFiles.SelectedItem
})

$Sync.Gui.mnuListCopy.add_Click({
    # copy listbox selected item text to clipboard
    Set-Clipboard -Value $Sync.Gui.lstFiles.SelectedItem
})
#endregion

#region Window events
$Sync.Window.add_Loaded({
    $Sync.Gui.txtFilter.Focus()
})

$Sync.Window.add_PreviewKeyDown({
    if ($_.Key -eq "Escape") {
        $Sync.Gui.txtFilter.Text = [string]::Empty
    }
})

$Sync.Gui.mnuFilterCut.add_Click({
    [string]$txt = $Sync.Gui.txtFilter.Text
    [int]$StartPos = $Sync.Gui.txtFilter.SelectionStart
    [string]$NewTxt = $txt.Substring(0, $StartPos) + $txt.Substring($StartPos + $Sync.Gui.txtFilter.SelectionLength)

    $txt = $txt.Substring($StartPos, $Sync.Gui.txtFilter.SelectionLength)
    Set-Clipboard $txt

    $Sync.Gui.txtFilter.Text = $NewTxt
    $Sync.Gui.txtFilter.SelectionStart = $StartPos
})

$Sync.Gui.mnuFilterCopy.add_Click({
    [int]$StartPos = $Sync.Gui.txtFilter.SelectionStart
    Set-Clipboard $Sync.Gui.txtFilter.Text.Substring($StartPos, $Sync.Gui.txtFilter.SelectionLength)
})

$Sync.Gui.mnuFilterPaste.add_Click({
    [string]$txt = $Sync.Gui.txtFilter.Text
    [int]$StartPos = $Sync.Gui.txtFilter.SelectionStart
    [string]$ClipboardText = Get-Clipboard -Raw
    [string]$NewTxt = $txt.Substring(0, $StartPos) + $ClipboardText + $txt.Substring($StartPos + $Sync.Gui.txtFilter.SelectionLength)

    $Sync.Gui.txtFilter.Text = $NewTxt
    $Sync.Gui.txtFilter.SelectionStart = $StartPos + $ClipboardText.Length
})

$Sync.Gui.mnuFilterClear.add_Click({
    $Sync.Gui.txtFilter.Text = [string]::Empty
})

$Sync.Gui.mnuFilterClearPaste.add_Click({
    [string]$ClipboardText = Get-Clipboard -Raw
    $Sync.Gui.txtFilter.Text = $ClipboardText
    $Sync.Gui.txtFilter.SelectionStart = $ClipboardText.Length
})
#endregion

# display the form
[void]$Sync.Window.ShowDialog()