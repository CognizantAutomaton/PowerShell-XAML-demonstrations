# PowerShell-XAML-demonstrations

The files in this repository contain various demonstrations of ways to manipulate various WPF/XAML controls in PowerShell.

## Filter XAML ListBox Without ViewModel.ps1
![Screenshot](/Filter%20XAML%20ListBox%20Without%20ViewModel.png?raw=true)

This example showcases filtering a ListBox with the TextBox TextChanged event. In this case, it is filtering the contents of the Program Files folder.

The ListBox does not use a ViewModel, rather, its DataSource is a PowerShell array.

To refresh the ListBox when the TextBox invokes the filter on the ListBox ItemsSource, the script uses the method:

```
[System.Windows.Data.CollectionViewSource]::GetDefaultView
```

-----

## TabControl_Template.ps1
![Screenshot](/TabControl_Template.png?raw=true)

Someone on reddit was looking for a TabControl that could dynamically generate tabpages based on a table. With XAML templates, the solution was quite short.

-----

## WPF Datagrid File Progress ViewModel with hyperlink and IValueConverter - a multithreading runspace demo.ps1
![Screenshot](/WPF%20Datagrid%20File%20Progress%20ViewModel%20with%20hyperlink%20and%20IValueConverter%20-%20a%20multithreading%20runspace%20demo.png?raw=true)

Uhh, okay so there is a bit to unpack with this one.

The focus was to get an IValueConverter to render filesizes with appropriate units in the cells of a DataGrid. There's also a progress bar just for the fun of it.

Another feature includes multithreading with runsapces to update the progress bar, with stop and pause buttons.

The DataGrid ItemsSource is based on a C# ViewModel. In order to ensure the cells in the DataGrid are refreshed properly with new data, the C# ViewModel makes plenty use of:

```
OnPropertyChanged
```

The hypertext links in the cells are there to demonstrate invoking the launch of files and websites from the DataGrid cells during the mouse click event.

-----

## XAML Templated ContentControl Without ViewModel.ps1
![Screenshot](/XAML%20Templated%20ContentControl%20Without%20ViewModel.png?raw=true)

This script demonstrates the use of XAML templates refreshing the ItemsSource of a templated ContentControl form element based on an ObservableCollection databinding. The DataBinding in this case was done purely in PowerShell, and did not require the use of a ViewModel.

Pretty basic. Click the button, it generates random junk, but I think it conveys the power of XAML templates quite well.

-----

## XAML Templated ItemsControl ViewModel.ps1
![Screenshot](/XAML%20Templated%20ItemsControl%20ViewModel.png?raw=true)

This script covers a similar topic as the previous script, but this time it is a collection of templated ItemsControl elements where a C# ViewModel is in use.

The ItemsControl can render a collection of rows in the ItemsSource, which allows the possibility to have great flexibility in regards to how each item is rendered.
