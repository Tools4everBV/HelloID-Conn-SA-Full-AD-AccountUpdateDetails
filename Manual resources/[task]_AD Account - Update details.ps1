$userPrincipalName = $form.gridUsers.UserPrincipalName
$company = $form.company
$title = $form.title
$department = $form.department

try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } 
    Write-Information "Found AD user [$userPrincipalName]"        
} catch {
    Write-Error "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)"    
}

try {
    if([String]::IsNullOrEmpty($company) -eq $true) {
        Set-ADUser -Identity $adUSer -company $null
    } else {
        Set-ADUser -Identity $adUSer -company $company
    }
    
    Write-Information "Finished update attribute [company] of AD user [$userPrincipalName] to [$company]"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Successfully updated attribute [company] of AD user [$userPrincipalName] to [$company]" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log    
} catch {
    Write-Error "Could not update attribute [company] of AD user [$userPrincipalName] to [$company]. Error: $($_.Exception.Message)"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Failed to update attribute [company] of AD user [$userPrincipalName] to [$company]" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log      
}

try {
    if([String]::IsNullOrEmpty($department) -eq $true) {
        Set-ADUser -Identity $adUSer -department $null
    } else {
        Set-ADUser -Identity $adUSer -department $department
    }
    
    Write-Information "Finished update attribute [department] of AD user [$userPrincipalName] to [$department]"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Successfully updated attribute [department] of AD user [$userPrincipalName] to [$department]" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log        
} catch {
    Write-Error "Could not update attribute [department] of AD user [$userPrincipalName] to [$department]. Error: $($_.Exception.Message)"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Failed to update attribute [department] of AD user [$userPrincipalName] to [$department]" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log     
}

try {
    if([String]::IsNullOrEmpty($title) -eq $true) {
        Set-ADUser -Identity $adUSer -title $null
    } else {
        Set-ADUser -Identity $adUSer -title $title
    }
    
    Write-Information "Finished update attribute [title] of AD user [$userPrincipalName] to [$title]"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Successfully updated attribute [title] of AD user [$userPrincipalName] to [$title]" # required (free format text) 
            IsError           = $false # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log    
} catch {
    Write-Error "Could not update attribute [title] of AD user [$userPrincipalName] to [$title]. Error: $($_.Exception.Message)"
    $Log = @{
            Action            = "UpdateAccount" # optional. ENUM (undefined = default) 
            System            = "ActiveDirectory" # optional (free format text) 
            Message           = "Failed to update attribute [title] of AD user [$userPrincipalName] to [$title]" # required (free format text) 
            IsError           = $true # optional. Elastic reporting purposes only. (default = $false. $true = Executed action returned an error) 
            TargetDisplayName = $adUser.name # optional (free format text) 
            TargetIdentifier  = $([string]$adUser.SID) # optional (free format text) 
        }
    #send result back  
    Write-Information -Tags "Audit" -MessageData $log    
}
