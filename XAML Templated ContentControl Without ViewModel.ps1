Add-Type -AssemblyName PresentationFramework, PresentationCore

$ErrorActionPreference = "Stop"

[Xml]$XAML = @"
<Window x:Name="Demo" x:Class="Demo.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Demo"
        mc:Ignorable="d"
        Title="Demo app" Visibility="Visible" Height="140" Width="700">
    <DockPanel>
        <Menu DockPanel.Dock="Top">
            <MenuItem Header="_Menu">
            </MenuItem>
        </Menu>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="45"/>
                <RowDefinition Height="25"/>
            </Grid.RowDefinitions>
            <ScrollViewer Grid.Row="0">
                <ContentControl
                    Name="ItemControl"
                    Content="{Binding Path=.}">
                    <ContentControl.ContentTemplate>
                        <DataTemplate>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="50"/>
                                    <ColumnDefinition Width="350"/>
                                    <ColumnDefinition Width="50"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="Guid:" HorizontalAlignment="Right" VerticalAlignment="Center" Height="25"/>
                                <TextBlock Grid.Column="1" Text="{Binding Guid}" HorizontalAlignment="Left" VerticalAlignment="Center" Height="25" Margin="5,0,0,0"/>
                                <TextBlock Grid.Column="2" Text="File path:" Height="25" VerticalAlignment="Center"/>
                                <TextBox Grid.Column="3" Text="{Binding FilePath}" HorizontalAlignment="Left" VerticalAlignment="Center" Height="25" Margin="5,0,0,0"/>
                            </Grid>
                        </DataTemplate>
                    </ContentControl.ContentTemplate>
                </ContentControl>
            </ScrollViewer>
            <Button
                Grid.Row="1"
                Name="btnGenerate"
                Content="Generate New"
                Width="100"
                HorizontalAlignment="Center"
                />
        </Grid>
    </DockPanel>
</Window>
"@

$SyncHash = [Hashtable]::Synchronized(@{})

$XAML.Window.RemoveAttribute('x:Class')
$XAML.Window.RemoveAttribute('mc:Ignorable')

$WpfNs = New-Object -TypeName Xml.XmlNamespaceManager -ArgumentList $XAML.NameTable
$WpfNs.AddNamespace('x', $XAML.DocumentElement.x)
$WpfNs.AddNamespace('d', $XAML.DocumentElement.d)
$WpfNs.AddNamespace('mc', $XAML.DocumentElement.mc)

# Read XAML markup
try {
    $Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $XAML))
} catch {
    Write-Host $_ -ForegroundColor Red
    Exit
}

# provide a reference to each GUI form control
$SyncHash.Window = $Window
$SyncHash.Gui = @{}
$XAML.SelectNodes('//*[@Name]', $WpfNs) | ForEach-Object {
    $SyncHash.Gui.Add($_.Name, $Window.FindName($_.Name))
}

$SyncHash.MyDataView = New-Object System.Collections.ObjectModel.ObservableCollection[PSCustomObject]
$SyncHash.MyDataView.Add([PSCustomObject]@{
    Guid = (New-Guid).Guid
    FilePath = "C:\$(((Get-Verb).Verb | Sort-Object -Property { Get-Random } | Select-Object -First 3) -join "\")"
})
$SyncHash.Gui.ItemControl.DataContext = $SyncHash.MyDataView

$Binding = New-Object System.Windows.Data.Binding -ArgumentList "[0]"
$Binding.Path = "[0]"
$Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
[void][System.Windows.Data.BindingOperations]::SetBinding($SyncHash.Gui.ItemControl, [System.Windows.Controls.ContentControl]::ContentProperty, $Binding)

$SyncHash.Gui.btnGenerate.add_Click({
    $SyncHash.MyDataView[0] = @{
        Guid = (New-Guid).Guid
        FilePath = "C:\$(((Get-Verb).Verb | Sort-Object -Property { Get-Random } | Select-Object -First 3) -join "\")"
    }
})

$SyncHash.Window.ShowDialog()