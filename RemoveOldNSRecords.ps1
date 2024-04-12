$list = ""
$DCs = New-Object Collections.Generic.List[String]
$DCs_draft = Get-ADDomainController -Filter * | Select HostName

foreach ( $DCHostName in $DCs_draft ) {
    $DCHostName = $DCHostName.HostName.ToLower()
    $DCs.Add($DCHostName + ".")
}

Write-Host "`nAuto-detected Name Servers:" -ForegroundColor Cyan
Write-Host $DCs -ForegroundColor Yellow
$addMore = Read-Host "`nWould you like to add more name servers? (Y/N)"

while($addMore -eq "Y" -or $addMore -eq "y"){
    $newServer = Read-Host "`nEnter the name server to add (please ensure it ends with '.')"
    $DCs.Add($newServer)
    $addMore = Read-Host "`nAdd another server? (Y/N)"
}

Write-Host "`nFinal Name Servers List:" -ForegroundColor Cyan
Write-Host $DCs -ForegroundColor Yellow
$confirmation = Read-Host "`nPlease verify there aren't extra or missing name servers in the list above. Proceed? (Y/N)"

if($confirmation -eq "Y" -or $confirmation -eq "y"){

    Write-Host "`nWorking..." -ForegroundColor Green

    $allZones = Get-DnsServerZone | Select ZoneName, isReverseLookupZone

    foreach ( $zone in $allZones ){
        $records = (Get-DnsServerResourceRecord -ZoneName $zone.ZoneName -RRType "NS");

        foreach ( $record in $records ){
            if ( $DCs -NotContains $record.RecordData.NameServer ){
                $list += $record.RecordData.NameServer + "	" + $zone.ZoneName + "`n"
            }
        }
    }

    Write-Host "`nFollowing records will be deleted:" -ForegroundColor Red
    Write-Host $list -ForegroundColor Yellow

    $confirmation = Read-Host "`nDo you want to proceed with deletion? (Y/N)"

    if($confirmation -eq "Y" -or $confirmation -eq "y"){
        foreach ( $zone in $allZones ){
            $records = (Get-DnsServerResourceRecord -ZoneName $zone.ZoneName -RRType "NS");

            foreach ( $record in $records ){
                if ( $DCs -NotContains $record.RecordData.NameServer ){
                    Remove-DnsServerResourceRecord -ZoneName $zone.ZoneName -RRType "NS" -Name "@" -RecordData $record.RecordData.NameServer -Confirm:$false -Force
                }
            }
        }
        Write-Host "`nRecords deleted." -ForegroundColor Green
    } else {
        Write-Host "`nDeletion cancelled." -ForegroundColor Red
    }
} else {
    Write-Host "`nOperation cancelled." -ForegroundColor Red
}
