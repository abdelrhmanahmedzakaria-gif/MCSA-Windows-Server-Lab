# MCSA Hands-On Project - Bulk create OUs, users and security groups
# Domain: abdo.local | 3 departments (Sales, HR, Marketing) x 5 users = 15 users
# Run on the Domain Controller with the Active Directory PowerShell module.

$DomainDN        = "DC=abdo,DC=local"
$Departments     = @("Sales", "HR", "Marketing")
$UsersPerDept    = 5
$DefaultPassword = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force

foreach ($dept in $Departments) {
    $ouDN = "OU=$dept,$DomainDN"

    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$dept'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $dept -Path $DomainDN -ProtectedFromAccidentalDeletion $true
        Write-Host "OU created: $dept"
    }

    $groupName = "$dept Group"
    if (-not (Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $groupName -GroupScope Global -GroupCategory Security -Path $ouDN
        Write-Host "Security group created: $groupName"
    }

    1..$UsersPerDept | ForEach-Object {
        $userName = "$dept$_"
        if (-not (Get-ADUser -Filter "SamAccountName -eq '$userName'" -ErrorAction SilentlyContinue)) {
            New-ADUser -Name $userName -SamAccountName $userName `
                -UserPrincipalName "$userName@abdo.local" `
                -Path $ouDN -AccountPassword $DefaultPassword -Enabled $true `
                -ChangePasswordAtLogon $true
            Add-ADGroupMember -Identity $groupName -Members $userName
            Write-Host "User created: $userName -> $groupName"
        }
    }
}

Write-Host "All 15 users created successfully!"
