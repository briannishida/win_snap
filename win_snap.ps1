<###########################################################################

   win_snap.ps1

   The results are stored as individual text files


   Written by:  Brian Nishida
   Date:        2019-01-25


############################################################################>

$startTime = Get-Date -UFormat "%Y-%m-%d_%H%M%S"
$machineName = hostname
$snapshotName = $machineName+"_"+$startTime

$snap_path     = Get-Location


<#
!!! User selection of what to snapshot !!!

Set to $True if you want that item snapshot-ed
Set to $False if you do not want that item snapshot-ed

#>

$snap_autoruns = $True
$snap_registry = $True
$snap_events   = $True
$snap_files    = $True
$snap_hashes   = $False
$snap_livedata = $True

$dirlist = @("C:\")
$dirlist_hashes = @("C:\")


# Create folder named after date-time of snapshot to store the results
$destinationPath = New-Item -Path $snap_path -Name $snapshotName -ItemType directory

cd $destinationPath


# Start Log
"Machine Name: "+$machineName | out-file summary.txt
"Start Time: "+$startTime | out-file summary.txt -Append


If($snap_livedata){

    # Processes
    "Writing Processes" | Tee-Object summary.txt -Append
    Get-Process | `
        Select-Object Id,ProcessName,Path | `
        Export-Csv -Path "processes.csv" -Encoding ASCII -NoTypeInformation


    # Services
    "Writing Services" | Tee-Object summary.txt -Append
    Get-Service | `
        Select-Object Status,StartType,Name,DisplayName | `
        Export-Csv -Path "services.csv" -Encoding ASCII -NoTypeInformation


    # TCP Connections
    "Writing Network Connections" | Tee-Object summary.txt -Append
    Get-NetTCPConnection | `
        Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,State,OwningProcess | `
        Export-Csv -Path "tcpconnections.csv" -Encoding ASCII -NoTypeInformation

    # For Windows 7 which does not have Get-NetTCPConnections
    # netstat -an > tcpconnections.csv
}

If($snap_files){

    # Files with CreationTime and LastWriteTime
    "Writing File Listing" | Tee-Object summary.txt -Append
    Get-ChildItem -Path $dirlist -File -Force -Recurse -ErrorAction SilentlyContinue | `
        Select-Object FullName,Name,Length,CreationTime,LastWriteTime | `
        Export-Csv -Path "files.csv" -Encoding ASCII -Force -NoTypeInformation

    "Writing Folder Listing" | Tee-Object summary.txt -Append
    Get-ChildItem -Path $dirlist -Directory -Force -Recurse -ErrorAction SilentlyContinue | `
        Select-Object FullName,Name,CreationTime | `
        Export-Csv -Path "folders.csv" -Encoding ASCII -Force -NoTypeInformation
}

If($snap_hashes){

	# MD5 hashes
	"Writing File Hashes" | Tee-Object summary.txt -Append
	Get-ChildItem -Path $dirlist_hashes -File -Force -Recurse -ErrorAction SilentlyContinue | `
	Get-FileHash -Algorithm MD5 -ErrorAction SilentlyContinue | `
	Export-Csv -Path "filehashes.csv" -Encoding ASCII -Force -NoTypeInformation

}

If($snap_registry){
    
    # Registry
    "Writing Registry Files" | Tee-Object summary.txt -Append
    reg.exe export hkcu hkcu.reg /y
    reg.exe export hklm hklm.reg /y
    reg.exe export hkcr hkcr.reg /y
    reg.exe export hku hku.reg /y
    reg.exe export hkcc hkcc.reg /y
}

If($snap_events){
    # Event Logs
    "Writing Event Logs" | Tee-Object summary.txt -Append
    $today = (Get-Date).Date

    Get-EventLog -LogName Application -After $today | `
	Select-Object TimeGenerated,EventID,EntryType,Message | `
	Export-csv -Path "eventlog_application.csv" -Encoding ASCII -NoTypeInformation

   Get-EventLog -LogName Security -After $today | `
	Select-Object TimeGenerated,EventID,EntryType,Message | `
	Export-csv -Path "eventlog_security.csv" -Encoding ASCII -NoTypeInformation

   Get-EventLog -LogName System -After $today | `
	Select-Object TimeGenerated,EventID,EntryType,Message | `
	Export-csv -Path "eventlog_system.csv" -Encoding ASCII -NoTypeInformation
}


If($snap_autoruns){
    
    # SysInternals autoruns
    "Writing autoruns data" | Tee-Object summary.txt -Append
    $autoruns_path = "${snap_path}autorunsc.exe"
    $autoruns_args = "-accepteula -a * -c -o autoruns.csv"
    Start-Process -FilePath $autoruns_path -ArgumentList $autoruns_args
}


# Finish Log
$endTime = Get-Date -UFormat "%Y-%m-%d_%H%M%S"
"End Time: "+$endTime | out-file summary.txt -Append

cd $snap_path
