# Input bindings are passed in via param block.
param($Timer)

# Add all your Azure Subscription Ids below
$subscriptionids = @"
[
"96f5c892-6dad-4a21-a3ed-cf0fe0184a65",
"1164a610-3045-4625-8105-8fce2ec53417",
"413524eb-1202-4d95-8e6c-9cfd9b0c1977"
]
"@ | ConvertFrom-Json

# Convert UTC to West Europe Standard Time zone
# If you live in a different Time zone, please make sure to update the $date variable below
# Check > https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones?view=windows-11#time-zones
$date = [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId([DateTime]::Now,"W. Europe Standard Time")

foreach ($subscriptionid in $subscriptionids) {
# Selecting Azure Sub
Set-AzContext -SubscriptionId $SubscriptionID | Out-Null

$CurrentSub = (Get-AzContext).Subscription.Id
If ($CurrentSub -ne $SubscriptionID) {
Throw "Could not switch to SubscriptionID: $SubscriptionID"
}

$vms = Get-AzVM -Status | Where-Object {($_.tags.AutoShutdown -ne $null) -and ($_.tags.AutoStart -ne $null) -and ($_.tags.SundayPatching -ne $null)}
$now = $date

foreach ($vm in $vms) {

if (($vm.PowerState -eq 'VM running') -and ($date.dayofweek.value__ -in 1..6) -and ($now -gt $(get-date $($vm.tags.AutoShutdown))) ) {
Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -NoWait -Force
Write-Warning "Stop VM [1..6] - $($vm.Name)"
}

elseif (($vm.PowerState -eq 'VM running') -and ($date.dayofweek.value__ -eq 0) -and ($vm.tags.SundayPatching -eq 'Off') -and ($now -gt $(get-date $($vm.tags.AutoShutdown))) ) {
    Stop-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Confirm:$false -NoWait -Force
    Write-Warning "Stop VM [0] - $($vm.Name)"
}

elseif (($vm.PowerState -eq 'VM deallocated') -and ($now -gt $(get-date $($vm.tags.AutoStart))) -and ($now -lt $(get-date $($vm.tags.AutoShutdown))) ) {
Start-AzVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -NoWait
Write-Warning "Start VM - $($vm.Name)"
}

}
}