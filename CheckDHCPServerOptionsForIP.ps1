# Requires the DhcpServer module to be installed. Use 'Install-WindowsFeature -Name DHCP' to install the module.
# You can also use 'Import-Module DhcpServer' to import it.

function Get-DHCPDNSServers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, HelpMessage="Please provide the IP to search for")]
        [string]$IP
    )

    # Color output definitions
    $greenColor = [ConsoleColor]::Green
    $redColor = [ConsoleColor]::Red
    $yellowColor = [ConsoleColor]::Yellow

    # Initialize the list to store failed servers
    $FailedServers = @()

    $DHCPServers = Get-DhcpServerInDC
    foreach ($DHCPServer in $DHCPServers) {
        try {
            $ServerOptions = Get-DhcpServerv4OptionValue -Computer $DHCPServer.DnsName -OptionId 6 -ErrorAction Stop
            if ($ServerOptions.Value -Contains $IP) {
                $Output = [PSCustomObject]@{
                    "FQDN"        = $DHCPServer.DnsName
                    "DNS Servers" = $ServerOptions.Value -join ', '
                }
                Write-Host "Found server with matching IP: $($DHCPServer.DnsName)" -ForegroundColor $greenColor
                $Output
            }
        } catch {
            Write-Host "Error occurred when querying server: $($DHCPServer.DnsName). Error details: $($_.Exception.Message)" -ForegroundColor $redColor
            $FailedServers += $DHCPServer.DnsName
        }
    }

    if ($FailedServers.Count -gt 0) {
        Write-Host "Failed to query the following servers:" -ForegroundColor $yellowColor
        $FailedServers -join ', '
    }
}

# Invoke the function
Get-DHCPDNSServers
