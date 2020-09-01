$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties department | Select-Object department
    HID-Write-Status -Message "Finished searching AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
     
    $department = $adUser.department
     
    Hid-Write-Status -Message "Department: $department" -Event Information
    HID-Write-Summary -Message "Department: $department" -Event Information
     
    Hid-Add-TaskResult -ResultValue @{ department = $department }
} catch {
    HID-Write-Status -Message "Error retrieving AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error retrieving AD user [$userPrincipalName]" -Event Failed
     
    Hid-Add-TaskResult -ResultValue []
}