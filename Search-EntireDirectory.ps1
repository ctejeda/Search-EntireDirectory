function Search-EntireDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$Username,

        [Parameter(Mandatory=$false)]
        [string]$ComputerName,

        [Parameter(Mandatory=$false)]
        [string]$GroupName,

        [Parameter(Mandatory=$false)]
        [string]$ObjectSID,

        [Parameter(Mandatory=$false)]
        [string]$EmailAddress,

        [Parameter(Mandatory=$false)]
        [int]$SizeLimit = 1000,

        [Parameter(Mandatory=$false)]
        [switch]$ShowAllProperties,

        [Parameter(Mandatory=$false)]
        [string]$LogFilePath
    )

    # Function to handle logging
    function Write-Log {
        param ([string]$Message)
        if ($LogFilePath) {
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            "$timestamp - $Message" | Out-File -FilePath $LogFilePath -Append
        }
    }

    # Function to get group members, including nested groups
function Get-ADGroupMembersRecursive {
    param (
        [string]$GroupName,
        [string]$TopLevelGroup = $GroupName,
        [string]$NestedGroupName = $null
    )

    $groupMembers = Get-ADGroupMember -Identity $GroupName -ErrorAction SilentlyContinue

    foreach ($member in $groupMembers) {
        if ($member.objectClass -eq 'group') {
            # Recursively output members of the nested group, without listing the group itself first
            Get-ADGroupMembersRecursive -GroupName $member.Name -TopLevelGroup $TopLevelGroup -NestedGroupName $member.Name
        } else {
            # Output the user or non-group object
            [PSCustomObject]@{
                "Parent Group" = $TopLevelGroup
                "Members" = if ($NestedGroupName) { $NestedGroupName } else { $member.Name }
                "Sub Members" = if ($NestedGroupName) { $member.Name } else { $null }
            }
        }
    }
}

    # Determine which parameter was used and construct the LDAP filter
    $ldapFilter = ""
    $searchParam = ""
    if ($Username) {
        $ldapFilter = "(&(objectClass=user)(samAccountName=$Username))"
        $searchParam = "Username: $Username"
    } elseif ($ComputerName) {
        $ldapFilter = "(&(objectClass=computer)(name=$ComputerName))"
        $searchParam = "ComputerName: $ComputerName"
    } elseif ($GroupName) {
        $ldapFilter = "(&(objectClass=group)(name=$GroupName))"
        $searchParam = "GroupName: $GroupName"
    } elseif ($ObjectSID) {
        $ldapFilter = "(objectSID=$ObjectSID)"
        $searchParam = "ObjectSID: $ObjectSID"
    } elseif ($EmailAddress) {
        $ldapFilter = "(&(objectClass=user)(mail=$EmailAddress))"
        $searchParam = "EmailAddress: $EmailAddress"
    }

    if (-not $ldapFilter) {
        Write-Error "No valid search parameter provided."
        return
    }

    # Retrieve all domains in the forest
    $domains = (Get-ADForest).Domains

    # Initialize results array
    $searchResults = @()

    # Search each domain
    foreach ($domain in $domains) {
        try {
            $properties = if ($ShowAllProperties) { "*" } else { "name", "Samaccountname", "objectSid" }
            $objects = Get-ADObject -LDAPFilter $ldapFilter -ResultSetSize $SizeLimit -Server $domain -Properties $properties
            
            if ($objects) {
                foreach ($object in $objects) {
                    if ($object.objectClass -eq 'group') {
                        # Handle group members
                        $groupMembers = Get-ADGroupMembersRecursive -GroupName $object.Name
                        foreach ($member in $groupMembers) {
                            $searchResults += [PSCustomObject]@{
                                'Parent Group' = $object.Name
                                Members = $member.Members
                                'Sub Members' = $member.'Sub Members'
                            }
                        }
                    } else {
                        # Handle other objects
                        $result = [PSCustomObject]@{
                            Name = $object.name
                            Domain = $domain
                        }
                        # Include additional properties
                        foreach ($property in $object.psobject.Properties) {
                            if ($result.psobject.Properties.Name -contains $property.Name) {
                                continue
                            }
                            $result | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
                        }
                        $searchResults += $result
                    }
                }
                Write-Host "AD Object(s) found in Domain: $domain for $searchParam" -ForegroundColor Green
            } else {
                Write-Host "No AD Object found in domain $domain for $searchParam" -ForegroundColor Cyan
            }
        }
        catch {
            Write-Warning "An error occurred while searching in domain $domain for $searchParam : $_"
        }
    }

    return $searchResults
}
