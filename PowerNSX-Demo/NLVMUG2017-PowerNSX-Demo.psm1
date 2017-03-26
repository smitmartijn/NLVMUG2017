<#
 Primary author: Nick Bradford, nbradford@vmware.com
 Modified for NL VMUG by Martijn Smit, msmit@vmware.com

 Load PowerCLI & PowerNSX before running this.
#>

$simple_steps = @(
    {$tz = Get-NsxTransportZone -Name TZ_Unicast },
    {$newls = New-NsxLogicalSwitch -TransportZone $tz -Name MyLittleLogicalSwitch},
    {Get-VM -Name TestVM | Connect-NsxLogicalSwitch $newls | out-null}
)

$simple_cleanup = @(
    {Get-VM -Name TestVM | Disconnect-NsxLogicalSwitch -Confirm:$false},
    {Get-NsxLogicalSwitch -Name MyLittleLogicalSwitch | Remove-NsxLogicalSwitch -Confirm:$false}
)

$extended_steps = @(
    {$tz = Get-NsxTransportZone -Name TZ_Unicast },
    {$webls = New-NsxLogicalSwitch -TransportZone $tz -Name webls},
    {$appls = New-NsxLogicalSwitch -TransportZone $tz -Name appls},
    {$dbls = New-NsxLogicalSwitch -TransportZone $tz -Name dbls},
    {$transitls = New-NsxLogicalSwitch -TransportZone $tz -Name transitls},
    {$uplink = New-NsxEdgeInterfaceSpec -Index 0 -Name uplink -type uplink -ConnectedTo (Get-VDPortgroup dpg-private-network) -PrimaryAddress 172.30.0.150 -SubnetPrefixLength 24 -SecondaryAddresses 172.30.0.151},
    {$transit = New-NsxEdgeInterfaceSpec -Index 1 -Name transit -type internal -ConnectedTo (Get-nsxlogicalswitch transitls) -PrimaryAddress 172.16.1.1 -SubnetPrefixLength 29},
    {New-NSXEdge -Name edge01 -Cluster (Get-Cluster Compute) -Datastore (Get-Datastore data) -Password VMware1!VMware1! -FormFactor compact -Interface $uplink,$transit -FwDefaultPolicyAllow | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | Set-NsxEdgeRouting -DefaultGatewayAddress 172.30.0.1 -confirm:$false | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgp -LocalAS 100 -RouterId 172.16.1.1 -confirm:$false | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | Set-NsxEdgeBgp -DefaultOriginate -confirm:$false | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | Set-NsxEdgeRouting -EnableBgpRouteRedistribution -confirm:$false | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | New-NsxEdgeBgpNeighbour -IpAddress 172.16.1.3 -RemoteAS 100 -confirm:$false | out-null},
    {Get-NSXEdge edge01 | Get-NsxEdgeRouting | New-NsxEdgeRedistributionRule -Learner bgp -FromStatic -confirm:$false | out-null},
    {$uplinklif = New-NsxLogicalRouterInterfaceSpec -Name Uplink -Type uplink -ConnectedTo (Get-NsxLogicalSwitch transitls) -PrimaryAddress 172.16.1.2 -SubnetPrefixLength 29},
    {$weblif = New-NsxLogicalRouterInterfaceSpec -Name web -Type internal -ConnectedTo (Get-NsxLogicalSwitch webls) -PrimaryAddress 10.0.1.1 -SubnetPrefixLength 24},
    {$applif = New-NsxLogicalRouterInterfaceSpec -Name app -Type internal -ConnectedTo (Get-NsxLogicalSwitch appls) -PrimaryAddress 10.0.2.1 -SubnetPrefixLength 24},
    {$dblif = New-NsxLogicalRouterInterfaceSpec -Name db -Type internal -ConnectedTo (Get-NsxLogicalSwitch dbls) -PrimaryAddress 10.0.3.1 -SubnetPrefixLength 24},
    {New-NsxLogicalRouter -Name LogicalRouter01 -ManagementPortGroup (Get-VDPortgroup dpg-private-network) -Interface $uplinklif,$weblif,$applif,$dblif -Cluster (Get-Cluster Compute) -Datastore (Get-Datastore data) | out-null},
    {Get-NsxLogicalRouter LogicalRouter01 | Get-NsxLogicalRouterRouting | Set-NsxLogicalRouterRouting -EnableBgp -ProtocolAddress 172.16.1.3 -ForwardingAddress 172.16.1.2 -LocalAS 100 -RouterId 172.16.1.3 -confirm:$false | out-null},
    {Get-NsxLogicalRouter LogicalRouter01 | Get-NsxLogicalRouterRouting | Set-NsxLogicalRouterRouting -EnableBgpRouteRedistribution -confirm:$false | out-null},
    {Get-NsxLogicalRouter LogicalRouter01 | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterRedistributionRule -FromConnected -Learner bgp -confirm:$false | out-null},
    {Get-NsxLogicalRouter LogicalRouter01 | Get-NsxLogicalRouterRouting | New-NsxLogicalRouterBgpNeighbour -IpAddress 172.16.1.1 -RemoteAS 100 -ForwardingAddress 172.16.1.2 -ProtocolAddress 172.16.1.3 -confirm:$false | out-null}
    {Get-NsxEdge edge01 | Get-NsxLoadBalancer | Set-NsxLoadBalancer -Enabled | out-null},
    {$monitor =  Get-NsxEdge edge01 | Get-NsxLoadBalancer | Get-NsxLoadBalancerMonitor -Name "default_http_monitor"},
    {$webpoolmember1 = New-NsxLoadBalancerMemberSpec -name Web01 -IpAddress 10.0.1.11 -Port 80},
    {$webpoolmember2 = New-NsxLoadBalancerMemberSpec -name Web02 -IpAddress 10.0.1.12 -Port 80},
    {$apppoolmember1 = New-NsxLoadBalancerMemberSpec -name App01 -IpAddress 10.0.2.11 -Port 80},
    {$apppoolmember2 = New-NsxLoadBalancerMemberSpec -name App02 -IpAddress 10.0.2.12 -Port 80},
    {$WebPool = Get-NsxEdge edge01 | Get-NsxLoadBalancer | New-NsxLoadBalancerPool -name WebPool1 -Description "Web Tier Pool" -Transparent:$false -Algorithm "round-robin" -Memberspec $webpoolmember1, $webpoolmember2 -Monitor $Monitor},
    {$AppPool = Get-NsxEdge edge01 | Get-NsxLoadBalancer | New-NsxLoadBalancerPool -name AppPool1 -Description "App Tier Pool" -Transparent:$false -Algorithm "round-robin" -Memberspec $apppoolmember1, $apppoolmember2 -Monitor $Monitor},
    {$WebAppProfile = Get-NsxEdge edge01 | Get-NsxLoadBalancer | New-NsxLoadBalancerApplicationProfile -Name WebAppProfile -Type http},
    {$AppAppProfile = Get-NsxEdge edge01 | Get-NsxLoadBalancer | new-NsxLoadBalancerApplicationProfile -Name AppAppProfile -Type http},
    {Get-NsxEdge edge01 | Get-NsxLoadBalancer | Add-NsxLoadBalancerVip -name WebVIP -Description WebVIP -ipaddress 172.30.0.151 -Protocol http -Port 80 -ApplicationProfile $WebAppProfile -DefaultPool $WebPool -AccelerationEnabled | out-null},
    {Get-NsxEdge edge01 | Get-NsxLoadBalancer | Add-NsxLoadBalancerVip -name AppVIP -Description AppVIP -ipaddress 172.16.1.1 -Protocol http -Port 80 -ApplicationProfile $AppAppProfile -DefaultPool $AppPool -AccelerationEnabled | out-null},
    {Get-VM | where { $_.name -match 'web'} | Connect-NsxLogicalSwitch $webls | out-null},
    {Get-VM | where { $_.name -match 'app'} | Connect-NsxLogicalSwitch $appls | out-null},
    {Get-VM | where { $_.name -match 'db'} | Connect-NsxLogicalSwitch $dbls | out-null}
)

$extended_cleanup = @(
    {Get-VApp | Get-VM | Disconnect-NsxLogicalSwitch -Confirm:$false},
    {Get-NsxEdge | Remove-NsxEdge -Confirm:$false},
    {Get-NsxLogicalRouter | Remove-NsxLogicalRouter -Confirm:$false},
    {Get-NsxLogicalSwitch -Name webls | Remove-NsxLogicalSwitch -Confirm:$false},
    {Get-NsxLogicalSwitch -Name appls | Remove-NsxLogicalSwitch -Confirm:$false},
    {Get-NsxLogicalSwitch -Name dbls | Remove-NsxLogicalSwitch -Confirm:$false},
    {Get-NsxLogicalSwitch -Name transitls | Remove-NsxLogicalSwitch -Confirm:$false}
)


function VMUG-ExtendedDemo
{
    foreach ($step in $extended_steps)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        write-host "Press a key to run the command..."
        # wait for a keypress to continue
        $junk = [console]::ReadKey($true)

        # execute (dot source) me in global scope
        . $step
    }
}

function VMUG-ExtendedDemoCleanup
{
    foreach ($step in $extended_cleanup)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        # execute (dot source) me in global scope
        . $step
    }
}


function VMUG-SimpleDemo
{
    foreach ($step in $simple_steps)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        write-host "Press a key to run the command..."
        # wait for a keypress to continue
        $junk = [console]::ReadKey($true)

        # execute (dot source) me in global scope
        . $step
    }
}

function VMUG-SimpleDemoCleanup
{
    foreach ($step in $simple_cleanup)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        # execute (dot source) me in global scope
        . $step
    }
}

function VMUG-Disconnect
{
    $disconnect_steps = @(
        {Disconnect-VIServer -confirm:$false},
        {Disconnect-NsxServer -confirm:$false}
    )

    foreach ($step in $disconnect_steps)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        # execute (dot source) me in global scope
        . $step
    }
}

function VMUG-Connect
{
    $connect_steps = @(
        {Connect-NsxServer -server "nsx.lab.corp" -username admin -password VMware1! -viusername administrator@vsphere.local -vipassword VMware1! -ViWarningAction "Ignore"  | out-null }
    )


    foreach ($step in $connect_steps)
    {
        # Show me first
        write-host -foregroundcolor yellow ">>> $step"

        # execute (dot source) me in global scope
        . $step
    }
}
