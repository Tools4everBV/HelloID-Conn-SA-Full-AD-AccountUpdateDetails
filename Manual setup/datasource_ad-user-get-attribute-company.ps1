$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties company | Select-Object company
    HID-Write-Status -Message "Finished searching AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
     
    $company = $adUser.company
     
    Hid-Write-Status -Message "Company: $company" -Event Information
    HID-Write-Summary -Message "Company: $company" -Event Information
     
    Hid-Add-TaskResult -ResultValue @{ company = $company }
} catch {
    HID-Write-Status -Message "Error retrieving AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error retrieving AD user [$userPrincipalName]" -Event Failed
     
    Hid-Add-TaskResult -ResultValue []
}