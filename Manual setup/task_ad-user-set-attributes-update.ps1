try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName }
    HID-Write-Status -Message "Found AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
} catch {
    HID-Write-Status -Message "Could not find AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to find AD user [$userPrincipalName]" -Event Failed
}
 
try {
    if([String]::IsNullOrEmpty($company) -eq $true) {
        Set-ADUser -Identity $adUSer -company $null
    } else {
        Set-ADUser -Identity $adUSer -company $company
    }
     
    HID-Write-Status -Message "Finished update attribute [company] of AD user [$userPrincipalName] to [$company]" -Event Success
    HID-Write-Summary -Message "Successfully updated attribute [company] of AD user [$userPrincipalName] to [$company]" -Event Success
} catch {
    HID-Write-Status -Message "Could not update attribute [company] of AD user [$userPrincipalName] to [$company]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to update attribute [company] of AD user [$userPrincipalName] to [$company]" -Event Failed
}
 
try {
    if([String]::IsNullOrEmpty($department) -eq $true) {
        Set-ADUser -Identity $adUSer -department $null
    } else {
        Set-ADUser -Identity $adUSer -department $department
    }
     
    HID-Write-Status -Message "Finished update attribute [department] of AD user [$userPrincipalName] to [$department]" -Event Success
    HID-Write-Summary -Message "Successfully updated attribute [department] of AD user [$userPrincipalName] to [$department]" -Event Success
} catch {
    HID-Write-Status -Message "Could not update attribute [department] of AD user [$userPrincipalName] to [$department]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to update attribute [department] of AD user [$userPrincipalName] to [$department]" -Event Failed
}
 
try {
    if([String]::IsNullOrEmpty($title) -eq $true) {
        Set-ADUser -Identity $adUSer -title $null
    } else {
        Set-ADUser -Identity $adUSer -title $title
    }
     
    HID-Write-Status -Message "Finished update attribute [title] of AD user [$userPrincipalName] to [$title]" -Event Success
    HID-Write-Summary -Message "Successfully updated attribute [title] of AD user [$userPrincipalName] to [$title]" -Event Success
} catch {
    HID-Write-Status -Message "Could not update attribute [title] of AD user [$userPrincipalName] to [$title]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Failed to update attribute [title] of AD user [$userPrincipalName] to [$title]" -Event Failed
}