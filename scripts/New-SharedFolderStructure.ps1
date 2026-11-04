# MCSA Hands-On Project - Shared folder structure: Private / Department / All
# - Private  : one folder per user, visible only to that user
# - Department : one share per department, restricted to its security group
# - All      : common share for the whole domain
# Run on the file server (Domain Controller in this lab) as Administrator.

$Base       = "D:\Shares"
$Departments = @("Sales", "HR", "Marketing")

function Set-OwnerAcl {
    param([string]$Path, [string]$Identity, [string]$Rights = "Modify")
    $acl = Get-Acl $Path
    $acl.SetAccessRuleProtection($true, $false) # break inheritance, keep it explicit
    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity, $Rights, "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($rule)
    Set-Acl $Path $acl
}

New-Item -ItemType Directory -Path "$Base\All" -Force | Out-Null
New-SmbShare -Name "All" -Path "$Base\All" `
    -FullAccess "ABDO\Domain Users" -ErrorAction SilentlyContinue | Out-Null

foreach ($dept in $Departments) {
    # Department folder + share (group-based access, never per-user)
    $deptPath = "$Base\$dept"
    New-Item -ItemType Directory -Path $deptPath -Force | Out-Null
    New-SmbShare -Name $dept -Path $deptPath `
        -FullAccess "ABDO\$dept Group" -ErrorAction SilentlyContinue | Out-Null
    Set-OwnerAcl -Path $deptPath -Identity "ABDO\$dept Group"

    # Private folder per user - nobody else can even see inside, same department or not
    1..5 | ForEach-Object {
        $user    = "$dept$_"
        $private = "$Base\Private\$user"
        New-Item -ItemType Directory -Path $private -Force | Out-Null
        Set-OwnerAcl -Path $private -Identity "ABDO\$user"
        Write-Host "Private folder created: $user"
    }
}

Write-Host "Shared folder structure ready: Private / Department / All"
