$list = ""
$DCs = New-Object Collections.Generic.List[String]
$DCs_draft = Get-ADDomainController -Filter * | Select HostName
foreach ( $DCHostName in $DCs_draft ) {
$DCHostName = $DCHostName.HostName.ToLower()
$DCs.Add($DCHostName + ".")
}
$DCs
Write-Warning "Please verify there aren't extra or missing name servers in the above list." -WarningAction Inquire
Write-Host "Working..."
$reverseZones = (Get-DnsServerZone | Where-Object {$_.isReverseLookupZone -eq $true}).ZoneName;

foreach ( $zone in $reverseZones ){

	$records = (Get-DnsServerResourceRecord -ZoneName $zone -RRType "NS");

	foreach ( $record in $records ){

		if ( $DCs -NotContains $record.RecordData.NameServer ){
		    $list += $record.RecordData.NameServer + "	$zone`n"
            Remove-DnsServerResourceRecord -ZoneName $zone -RRType "NS" -Name "@" -RecordData $record.RecordData.NameServer -Confirm:$false -Force

        }
    }
}

Write-Host "Deleted the following records:"
$list