<###########################################################################

   lin_snap.ps1

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

$snap_files    = $True
$snap_hashes   = $False
$snap_livedata = $True

# do not search in /proc (too many changed, useless files) or /mediaq
$dirlist = @("/bin", "/boot", "/dev", "/etc", "/home", "/lib", "/lib64", `
	"/lost+found", "/mnt", "/opt", "/root", "/run", "/sbin", "/snap", `
	"/srv", "/sys", "/tmp", "/usr", "/var")

$dirlist_hashes = @("/")


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
    systemctl list-units --type service > services.csv


    # TCP Connections
    "Writing Network Connections" | Tee-Object summary.txt -Append
    netstat -pant > tcpconnections.csv
}


If($snap_files){

    # Files with CreationTime and LastWriteTime
    "Writing File Listing" | Tee-Object summary.txt -Append
    Get-ChildItem -Path $dirlist -File -Force -Recurse -ErrorAction SilentlyContinue | `
        Select-Object FullName,Name,Length,CreationTime,LastWriteTime | `
        Export-Csv -Path files.csv -Encoding ASCII -Force -NoTypeInformation

    "Writing Folder Listing" | Tee-Object summary.txt -Append
    Get-ChildItem -Path $dirlist -Directory -Force -Recurse -ErrorAction SilentlyContinue | `
        Select-Object FullName,Name,CreationTime | `
        Export-Csv -Path folders.csv -Encoding ASCII -Force -NoTypeInformation
}

If($snap_hashes){

	# MD5 hashes
    "Writing File Hashes" | Tee-Object summary.txt -Append

	Get-ChildItem -Path $dirlist_hashes -File -Force -Recurse -ErrorAction SilentlyContinue | `
		Get-FileHash -Algorithm MD5 -ErrorAction SilentlyContinue | `
		Export-Csv -Path filehashes.csv -Encoding ASCII -Force -NoTypeInformation
}


# Finish Log
$endTime = Get-Date -UFormat "%Y-%m-%d_%H%M%S"
"End Time: "+$endTime | out-file summary.txt -Append

cd $snap_path
