$IP = "172.16.3.145"
$FormatEnumerationLimit = -1
$Servers = Get-ADComputer -Filter { OperatingSystem -Like "*Windows Server*" }
$FailedServers = @()
ForEach ( $Server in $Servers ){
    try {
    $Result = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "IPEnabled = 'True'" -Property DNSServerSearchOrder -ComputerName $Server.Name -ErrorAction SilentlyContinue
    }
    catch {
     $FailedServers += $Server.Name
    }
    if ( $Result.DNSServerSearchOrder -Contains $IP ){
        $Output = New-Object PSObject 
        $Output | Add-Member NoteProperty "FQDN" $Server.DNSHostName
        $Output | Add-Member NoteProperty "DNS Server Search Order" $Result.DNSServerSearchOrder
        $Output
    }
}
