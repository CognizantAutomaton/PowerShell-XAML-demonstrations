Add-Type -AssemblyName PresentationFramework, PresentationCore

$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.ComponentModel;
using System.Runtime.CompilerServices;

public class MyViewModel : INotifyPropertyChanged {
    public event PropertyChangedEventHandler PropertyChanged;
    private string _guid;
    private string _filepath;

    public string Guid {
        get { return _guid; }
        set {
            _guid = value;
            OnPropertyChanged();
        }
    }
    public string FilePath {
        get { return _filepath; }
        set {
            _filepath = value;
            OnPropertyChanged();
        }
    }

    public void OnPropertyChanged([CallerMemberName]string caller = null) {
        var handler = PropertyChanged;
        if (handler != null) {
            handler(this, new PropertyChangedEventArgs(caller));
        }
    }

    public MyViewModel() {

    }
}
"@

[Xml]$XAML = @"
<Window x:Name="Demo" x:Class="Demo.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Demo"
        mc:Ignorable="d"
        Title="Demo app" Visibility="Visible" Height="400" Width="700">
    <DockPanel>
        <Menu DockPanel.Dock="Top">
            <MenuItem Header="_Menu">
            </MenuItem>
        </Menu>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition/>
                <RowDefinition Height="35"/>
            </Grid.RowDefinitions>
            <ScrollViewer
                Grid.Row="0"
                HorizontalAlignment="Stretch"
                VerticalAlignment="Stretch">
                <ItemsControl
                    Name="ItemList"
                    ItemsSource="{Binding Path=.}">
                    <ItemsControl.ItemTemplate>
                        <DataTemplate>
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="50"/>
                                    <ColumnDefinition Width="300"/>
                                    <ColumnDefinition Width="50"/>
                                    <ColumnDefinition Width="200"/>
                                </Grid.ColumnDefinitions>
                                <TextBlock Grid.Column="0" Text="Guid:"/>
                                <TextBox Grid.Column="1" Text="{Binding Guid}" Width="200" HorizontalAlignment="Left"/>
                                <TextBlock Grid.Column="2" Text="File path:"/>
                                <TextBox Grid.Column="3" Text="{Binding FilePath, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}" Width="200" HorizontalAlignment="Left"/>
                            </Grid>
                        </DataTemplate>
                    </ItemsControl.ItemTemplate>
                </ItemsControl>
            </ScrollViewer>
            <Button
                Grid.Row="1"
                Name="btnGenerate"
                HorizontalAlignment="Center"
                Content="Generate New"
                Width="100"/>
        </Grid>
    </DockPanel>
</Window>
"@

$SyncHash = [hashtable]::Synchronized( @{} )
$SyncHash.ViewFiles = New-Object System.Collections.ObjectModel.ObservableCollection[MyViewModel]

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

$SyncHash.Gui.ItemList.ItemsSource = $SyncHash.ViewFiles

$data = foreach ($n in @(1..20)) {
    New-Object MyViewModel -Property @{
        Guid = (New-Guid).Guid
        FilePath = "C:\$(((Get-Verb).Verb | Sort-Object -Property { Get-Random } | Select-Object -First 3) -join "\")"
    }
}

foreach ($item in $data) {
    $SyncHash.ViewFiles.Add($item)
}

$SyncHash.Gui.btnGenerate.add_Click({
    foreach ($item in $SyncHash.ViewFiles) {
        $item.Guid = (New-Guid).Guid
        $item.FilePath = "C:\$(((Get-Verb).Verb | Sort-Object -Property { Get-Random } | Select-Object -First 3) -join "\")"
    }
})

$SyncHash.Window.ShowDialog()