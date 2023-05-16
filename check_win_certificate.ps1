param(
    [string]$thumbprint  = $null,
    [string]$certstore   = 'My',
    [int]$warn           = '90',
    [int]$crit           = '30'
);

try {
    $cert = Get-ChildItem -Path cert:\LocalMachine\$certstore -Recurse | Where-Object {$_.Thumbprint -eq $thumbprint}
} catch {
    Write-Output "CRITICAL - Could not retrieve certificates."
    $returnCode = 2
    exit ($returnCode)
}

if ($cert -eq $null) {
    Write-Output "CRITICAL - No certificate found with Thumbprint $thumbprint"
    $returnCode = 2
    exit ($returnCode)
}

$tzId     = (([TimeZoneInfo]::Local.Id).split(" ") | foreach { $tz += $_[0]})
$certExp  = $cert.NotAfter.ToString("yyyy-MM-dd hh:mm:ss")
$certName = [regex]::Match($cert.Subject, '(?<==)(.*?)(?=,)')
$walert   = $cert.NotAfter.AddDays(-$warn)
$calert   = $cert.NotAfter.AddDays(-$crit)
$today    = Get-Date
$dtoExp   = (New-TimeSpan -Start $today -End $cert.NotAfter).Days
$htoExp   = (New-TimeSpan -Start $today -End $cert.NotAfter).Hours
$mtoExp   = (New-TimeSpan -Start $today -End $cert.NotAfter).Minutes

$dstring = "will expire in "
if ($dtoExp -gt 1) { $dstring += "$dtoExp days" }
elseif ($dtoExp -eq 1) { $dstring += "$dtoExp day" }
elseif (($dtoExp -eq 0) -and (($htoExp -ge 0) -and ($mtoExp -ge 0))) {
    if ($htoExp -eq 0) {
        if ($mtoExp -eq 1) { $dstring += "1 minute" }
        else { $dstring += "$mtoExp minutes" }
    }
    else {
        if ($htoExp -eq 1) { $dstring += "1 hour" }
        else { $dstring += "$htoExp hours" }
    }
}
else { $dstring = "has expired" }

if (($calert) -lt ($today)) {
   $returnCode = 2
   $rcode = "CRITICAL -"
} elseif (($walert) -lt ($today)) {
   $returnCode = 1
   $rcode = "WARNING -"
} else {
   $returnCode = 0
   $rcode = "OK -"
}

Write-Output "$rcode Certificate '$certName' $dstring ($certExp[$tz])."

exit ($returnCode)
