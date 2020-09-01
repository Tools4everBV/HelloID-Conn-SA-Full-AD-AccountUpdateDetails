$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties title | Select-Object title
    HID-Write-Status -Message "Finished searching AD user [$userPrincipalName]" -Event Information
    HID-Write-Summary -Message "Found AD user [$userPrincipalName]" -Event Information
     
    $title = $adUser.title
     
    Hid-Write-Status -Message "Title: $title" -Event Information
    HID-Write-Summary -Message "Title: $title" -Event Information
     
    Hid-Add-TaskResult -ResultValue @{ title = $title }
} catch {
    HID-Write-Status -Message "Error retrieving AD user [$userPrincipalName]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error retrieving AD user [$userPrincipalName]" -Event Failed
     
    Hid-Add-TaskResult -ResultValue []
}