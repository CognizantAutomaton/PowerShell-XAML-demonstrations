Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName PresentationCore, PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# init synchronized hashtable
$Sync = [HashTable]::Synchronized(@{})
$hashtable = @{
    "John" = @("data 1", "data 2", "data 3")
    "Jane" = @("data 4", "data 5", "data 6")
    "Joe" = @("data 7", "data 8", "data 9")
}

# init runspace
$Runspace = [RunspaceFactory]::CreateRunspace()
$Runspace.ApartmentState = [Threading.ApartmentState]::STA
$Runspace.ThreadOptions = "ReuseThread"         
$Runspace.Open()

# provide the other thread with the synchronized hashtable (variable shared across threads)
$Runspace.SessionStateProxy.SetVariable("Sync", $Sync)

# paste XAML here
[Xml]$WpfXml = @"
    <Window     
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Tab ListBox"
        Height="250"
        Width="475">
        <Grid>
            <Grid.Resources>
                <DataTemplate x:Key="CustomHeaderTemplate">
                    <Label Content="{Binding Key}" />
                </DataTemplate>
                <DataTemplate x:Key="CustomItemTemplate">
                    <ListBox ItemsSource="{Binding Value}"/>
                </DataTemplate>
            </Grid.Resources>
            <Grid HorizontalAlignment="Center" VerticalAlignment="Center" Height="150" Width="400">
                <TabControl x:Name="TabControl"
                    Margin="10"
                    ItemTemplate="{StaticResource CustomHeaderTemplate}"
                    ContentTemplate="{StaticResource CustomItemTemplate}">
                </TabControl>
            </Grid>
        </Grid>
    </Window>
"@

# these attributes can disturb powershell's ability to load XAML, so remove them
$WpfXml.Window.RemoveAttribute('x:Class')
$WpfXml.Window.RemoveAttribute('mc:Ignorable')

# add namespaces for later use if needed
$WpfNs = New-Object -TypeName Xml.XmlNamespaceManager -ArgumentList $WpfXml.NameTable
$WpfNs.AddNamespace('x', $WpfXml.DocumentElement.x)
$WpfNs.AddNamespace('d', $WpfXml.DocumentElement.d)
$WpfNs.AddNamespace('mc', $WpfXml.DocumentElement.mc)

$Sync.Gui = @{}

# Read XAML markup
try {
    $Sync.Window = [Windows.Markup.XamlReader]::Load((New-Object System.Xml.XmlNodeReader $WpfXml))
} catch {
    Write-Host $_ -ForegroundColor Red
    Exit
}

#===================================================
# Retrieve a list of all GUI elements
#===================================================
$WpfXml.SelectNodes('//*[@x:Name]', $WpfNs) | ForEach-Object {
    $Sync.Gui.Add($_.Name, $Sync.Window.FindName($_.Name))
}

$Sync.Gui.TabControl.ItemsSource = $hashtable.GetEnumerator() | Sort-Object -Property Key

# display the form
[void]$Sync.Window.ShowDialog()
