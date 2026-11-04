# MCSA Hands-On Project - Restrict logon hours to 09:00-17:00, Monday-Friday
# Applies to all 15 lab users in one run (no per-user clicking).
# logonHours is a 21-byte bitmask: 168 bits, bit 0 = Sunday 00:00-01:00.

Import-Module ActiveDirectory

$hours = New-Object byte[] 21

# Monday..Friday start at bit 24, 48, 72, 96, 120; allow hours 09:00-16:59
foreach ($dayStart in @(24, 48, 72, 96, 120)) {
    for ($h = 9; $h -lt 17; $h++) {
        $bit = $dayStart + $h
        $byteIndex = [math]::Floor($bit / 8)
        $hours[$byteIndex] = $hours[$byteIndex] -bor (1 -shl ($bit % 8))
    }
}

Get-ADUser -Filter * -SearchBase "DC=abdo,DC=local" |
    Where-Object { $_.SamAccountName -notlike "IT_*" } |
    ForEach-Object {
        Set-ADUser -Identity $_ -Replace @{ logonHours = $hours }
        Write-Host "Logon Hours applied: $($_.SamAccountName)"
    }

Write-Host "Logon Hours applied to all 15 users (9 AM - 5 PM)"
