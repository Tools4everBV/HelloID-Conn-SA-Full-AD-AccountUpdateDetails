#HelloID variables
$PortalBaseUrl = "https://CUSTOMER.helloid.com"
$apiKey = "API_KEY"
$apiSecret = "API_SECRET"
$delegatedFormAccessGroupNames = @("Users", "HID_administrators")

 
# Create authorization headers with HelloID API key
$pair = "$apiKey" + ":" + "$apiSecret"
$bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
$base64 = [System.Convert]::ToBase64String($bytes)
$key = "Basic $base64"
$headers = @{"authorization" = $Key}
# Define specific endpoint URI
if($PortalBaseUrl.EndsWith("/") -eq $false){
    $PortalBaseUrl = $PortalBaseUrl + "/"
}

function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }

    $host.UI.RawUI.ForegroundColor = $fc
}
 
 
$variableName = "ADusersSearchOU"
$variableGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automation/variables/named/$variableName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.automationVariableGuid)) {
        #Create Variable
        $body = @{
            name = "$variableName";
            value = '[{ "OU": "OU=Employees,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"},{ "OU": "OU=Disabled,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"},{"OU": "OU=External,OU=Users,OU=Enyoi,DC=enyoi-media,DC=local"}]';
            secret = "false";
            ItemType = 0;
        }
  
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automation/variable")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $variableGuid = $response.automationVariableGuid

        Write-ColorOutput Green "Variable '$variableName' created: $variableGuid"
    } else {
        $variableGuid = $response.automationVariableGuid
        Write-ColorOutput Yellow "Variable '$variableName' already exists: $variableGuid"
    }
} catch {
    Write-ColorOutput Red "Variable '$variableName'"
    $_
}
  
  
  
$taskName = "AD-user-generate-table-wildcard"
$taskGetUsersGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
  
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
  
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
try {
    $searchValue = $formInput.searchUser
    $searchQuery = "*$searchValue*"
      
      
    if([String]::IsNullOrEmpty($searchValue) -eq $true){
        Hid-Add-TaskResult -ResultValue []
    }else{
        Hid-Write-Status -Message "SearchQuery: $searchQuery" -Event Information
        Hid-Write-Status -Message "SearchBase: $searchOUs" -Event Information
        HID-Write-Summary -Message "Searching for: $searchQuery" -Event Information
          
        $ous = $searchOUs | ConvertFrom-Json
        $users = foreach($item in $ous) {
            Get-ADUser -Filter {Name -like $searchQuery -or DisplayName -like $searchQuery -or userPrincipalName -like $searchQuery -or email -like $searchQuery} -SearchBase $item.ou -properties *
        }
          
        $users = $users | Sort-Object -Property DisplayName
        $resultCount = @($users).Count
        Hid-Write-Status -Message "Result count: $resultCount" -Event Information
        HID-Write-Summary -Message "Result count: $resultCount" -Event Information
          
        if($resultCount -gt 0){
            foreach($user in $users){
                $returnObject = @{SamAccountName=$user.SamAccountName; displayName=$user.displayName; UserPrincipalName=$user.UserPrincipalName; Description=$user.Description; Department=$user.Department; Title=$user.Title; Company=$user.company}
                Hid-Add-TaskResult -ResultValue $returnObject
            }
        } else {
            Hid-Add-TaskResult -ResultValue []
        }
    }
} catch {
    HID-Write-Status -Message "Error searching AD user [$searchValue]. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error searching AD user [$searchValue]" -Event Failed
      
    Hid-Add-TaskResult -ResultValue []
}
  
'@;
            automationContainer = "1";
            variables = @(@{name = "searchOUs"; value = "{{variable.ADusersSearchOU}}"; typeConstraint = "string"; secret = "False"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetUsersGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetUsersGuid"    
    } else {
        #Get TaskGUID
        $taskGetUsersGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetUsersGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
}  
  
  
$dataSourceName = "AD-user-generate-table-wildcard"
$dataSourceGetUsersGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "Company"; type = 0}, @{key = "Department"; type = 0}, @{key = "Description"; type = 0}, @{key = "displayName"; type = 0}, @{key = "SamAccountName"; type = 0}, @{key = "Title"; type = 0}, @{key = "UserPrincipalName"; type = 0});
            automationTaskGUID = "$taskGetUsersGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "searchUser"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
          
        $dataSourceGetUsersGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetUsersGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetUsersGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetUsersGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
  
  
  
$taskName = "AD-user-generate-table-attributes-basic"
$taskGetUserDetailsGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
  
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
  
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
try {
    $userPrincipalName = $formInput.selectedUser.UserPrincipalName
    HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
      
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties * | select displayname, samaccountname, userPrincipalName, mail, employeeID, Enabled
    HID-Write-Status -Message "Finished searching AD user [$userPrincipalName]" -Event Information
      
    foreach($tmp in $adUser.psObject.properties)
    {
        $returnObject = @{name=$tmp.Name; value=$tmp.value}
        Hid-Add-TaskResult -ResultValue $returnObject
    }
      
    HID-Write-Status -Message "Finished retrieving AD user [$userPrincipalName] basic attributes" -Event Success
    HID-Write-Summary -Message "Finished retrieving AD user [$userPrincipalName] basic attributes" -Event Success
} catch {
    HID-Write-Status -Message "Error retrieving AD user [$userPrincipalName] basic attributes. Error: $($_.Exception.Message)" -Event Error
    HID-Write-Summary -Message "Error retrieving AD user [$userPrincipalName] basic attributes" -Event Failed
      
    Hid-Add-TaskResult -ResultValue []
}
'@;
            automationContainer = "1";
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetUserDetailsGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetUserDetailsGuid"   
    } else {
        #Get TaskGUID
        $taskGetUserDetailsGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetUserDetailsGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
}
  
  
  
$dataSourceName = "AD-user-generate-table-attributes-basic"
$dataSourceGetUserDetailsGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "name"; type = 0}, @{key = "value"; type = 0});
            automationTaskGUID = "$taskGetUserDetailsGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "selectedUser"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
          
        $dataSourceGetUserDetailsGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetUserDetailsGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetUserDetailsGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetUserDetailsGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
} 
 
 
 
$taskName = "AD-user-get-attribute-company"
$taskGetCompanyGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
  
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
  
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties company | select company
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
'@;
            automationContainer = "1";
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetCompanyGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetCompanyGuid"   
    } else {
        #Get TaskGUID
        $taskGetCompanyGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetCompanyGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
}  
  
  
$dataSourceName = "AD-user-get-attribute-company"
$dataSourceGetCompanyGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "company"; type = 0});
            automationTaskGUID = "$taskGetCompanyGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "selectedUser"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
          
        $dataSourceGetCompanyGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetCompanyGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetCompanyGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetCompanyGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
  
 
 
$taskName = "AD-user-get-attribute-department"
$taskGetDepartmentGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
  
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
  
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties department | select department
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
'@;
            automationContainer = "1";
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetDepartmentGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetDepartmentGuid"    
    } else {
        #Get TaskGUID
        $taskGetDepartmentGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetDepartmentGuid"
    }
} catch {
    $_
    Write-ColorOutput Red "Powershell task '$taskName'"
}
  
  
  
$dataSourceName = "AD-user-get-attribute-department"
$dataSourceGetDepartmentGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "department"; type = 0});
            automationTaskGUID = "$taskGetDepartmentGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "selectedUser"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
          
        $dataSourceGetDepartmentGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetDepartmentGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetDepartmentGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetDepartmentGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
 
 
$taskName = "AD-user-get-attribute-title"
$taskGetTitleGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/automationtasks?search=$taskName&container=1")
    $response = (Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false) | Where-Object -filter {$_.name -eq $taskName}
  
    if([string]::IsNullOrEmpty($response.automationTaskGuid)) {
        #Create Task
  
        $body = @{
            name = "$taskName";
            useTemplate = "false";
            powerShellScript = @'
$UserPrincipalName = $formInput.selectedUser.UserPrincipalName
HID-Write-Status -Message "Searching AD user [$userPrincipalName]" -Event Information
 
try {
    $adUser = Get-ADuser -Filter { UserPrincipalName -eq $userPrincipalName } -Properties title | select title
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
'@;
            automationContainer = "1";
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskGetTitleGuid = $response.automationTaskGuid

        Write-ColorOutput Green "Powershell task '$taskName' created: $taskGetTitleGuid"    
    } else {
        #Get TaskGUID
        $taskGetTitleGuid = $response.automationTaskGuid
        Write-ColorOutput Yellow "Powershell task '$taskName' already exists: $taskGetTitleGuid"
    }
} catch {
    Write-ColorOutput Red "Powershell task '$taskName'"
    $_
}
  
  
  
$dataSourceName = "AD-user-get-attribute-title"
$dataSourceGetTitleGuid = ""
  
try {
    $uri = ($PortalBaseUrl +"api/v1/datasource/named/$dataSourceName")
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
  
    if([string]::IsNullOrEmpty($response.dataSourceGUID)) {
        #Create DataSource
        $body = @{
            name = "$dataSourceName";
            type = "3";
            model = @(@{key = "title"; type = 0});
            automationTaskGUID = "$taskGetTitleGuid";
            input = @(@{description = ""; translateDescription = "False"; inputFieldType = "1"; key = "selectedUser"; type = "0"; options = "1"})
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/datasource")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
          
        $dataSourceGetTitleGuid = $response.dataSourceGUID
        Write-ColorOutput Green "Task data source '$dataSourceName' created: $dataSourceGetTitleGuid"
    } else {
        #Get DatasourceGUID
        $dataSourceGetTitleGuid = $response.dataSourceGUID
        Write-ColorOutput Yellow "Task data source '$dataSourceName' already exists: $dataSourceGetTitleGuid"
    }
} catch {
    Write-ColorOutput Red "Task data source '$dataSourceName'"
    $_
}
 
 
  
$formName = "AD Account - Update details"
$formGuid = ""
  
try
{
    try {
        $uri = ($PortalBaseUrl +"api/v1/forms/$formName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
  
    if(([string]::IsNullOrEmpty($response.dynamicFormGUID)) -or ($response.isUpdated -eq $true))
    {
        #Create Dynamic form
        $form = @"
[
  {
    "label": "Select user account",
    "fields": [
      {
        "key": "searchfield",
        "templateOptions": {
          "label": "Search",
          "placeholder": "Username or email address"
        },
        "type": "input",
        "summaryVisibility": "Hide element",
        "requiresTemplateOptions": true
      },
      {
        "key": "gridUsers",
        "templateOptions": {
          "label": "Select user account",
          "required": true,
          "grid": {
            "columns": [
              {
                "headerName": "DisplayName",
                "field": "displayName"
              },
              {
                "headerName": "UserPrincipalName",
                "field": "UserPrincipalName"
              },
              {
                "headerName": "Department",
                "field": "Department"
              },
              {
                "headerName": "Title",
                "field": "Title"
              },
              {
                "headerName": "Description",
                "field": "Description"
              }
            ],
            "height": 300,
            "rowSelection": "single"
          },
          "dataSourceConfig": {
            "dataSourceGuid": "$dataSourceGetUsersGuid",
            "input": {
              "propertyInputs": [
                {
                  "propertyName": "searchUser",
                  "otherFieldValue": {
                    "otherFieldKey": "searchfield"
                  }
                }
              ]
            }
          },
          "useFilter": false
        },
        "type": "grid",
        "summaryVisibility": "Show",
        "requiresTemplateOptions": true
      }
    ]
  },
  {
    "label": "Details",
    "fields": [
      {
        "key": "gridDetails",
        "templateOptions": {
          "label": "Basic attributes",
          "required": false,
          "grid": {
            "columns": [
              {
                "headerName": "Name",
                "field": "name"
              },
              {
                "headerName": "Value",
                "field": "value"
              }
            ],
            "height": 350,
            "rowSelection": "single"
          },
          "dataSourceConfig": {
            "dataSourceGuid": "$dataSourceGetUserDetailsGuid",
            "input": {
              "propertyInputs": [
                {
                  "propertyName": "selectedUser",
                  "otherFieldValue": {
                    "otherFieldKey": "gridUsers"
                  }
                }
              ]
            }
          },
          "useFilter": false
        },
        "type": "grid",
        "summaryVisibility": "Hide element",
        "requiresTemplateOptions": true
      },
      {
        "key": "company",
        "templateOptions": {
          "label": "Company",
          "useDataSource": true,
          "displayField": "company",
          "dataSourceConfig": {
            "dataSourceGuid": "$dataSourceGetCompanyGuid",
            "input": {
              "propertyInputs": [
                {
                  "propertyName": "selectedUser",
                  "otherFieldValue": {
                    "otherFieldKey": "gridUsers"
                  }
                }
              ]
            }
          },
          "useFilter": false
        },
        "type": "input",
        "summaryVisibility": "Show",
        "requiresTemplateOptions": true
      },
      {
        "key": "department",
        "templateOptions": {
          "label": "Department",
          "useDataSource": true,
          "displayField": "department",
          "dataSourceConfig": {
            "dataSourceGuid": "$dataSourceGetDepartmentGuid",
            "input": {
              "propertyInputs": [
                {
                  "propertyName": "selectedUser",
                  "otherFieldValue": {
                    "otherFieldKey": "gridUsers"
                  }
                }
              ]
            }
          },
          "useFilter": false
        },
        "type": "input",
        "summaryVisibility": "Show",
        "requiresTemplateOptions": true
      },
      {
        "key": "title",
        "templateOptions": {
          "label": "Job title",
          "useDataSource": true,
          "displayField": "title",
          "dataSourceConfig": {
            "dataSourceGuid": "$dataSourceGetTitleGuid",
            "input": {
              "propertyInputs": [
                {
                  "propertyName": "selectedUser",
                  "otherFieldValue": {
                    "otherFieldKey": "gridUsers"
                  }
                }
              ]
            }
          },
          "useFilter": false
        },
        "type": "input",
        "summaryVisibility": "Show",
        "requiresTemplateOptions": true
      }
    ]
  }
]
"@
  
        $body = @{
            Name = "$formName";
            FormSchema = $form
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/forms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
  
        $formGuid = $response.dynamicFormGUID
        Write-ColorOutput Green "Dynamic form '$formName' created: $formGuid"
    } else {
        $formGuid = $response.dynamicFormGUID
        Write-ColorOutput Yellow "Dynamic form '$formName' already exists: $formGuid"
    }
} catch {
    Write-ColorOutput Red "Dynamic form '$formName'"
    $_
}  
  
  
  
$delegatedFormAccessGroupGuids = @()

foreach($group in $delegatedFormAccessGroupNames) {
    try {
        $uri = ($PortalBaseUrl +"api/v1/groups/$group")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
        $delegatedFormAccessGroupGuid = $response.groupGuid
        $delegatedFormAccessGroupGuids += $delegatedFormAccessGroupGuid
        
        Write-ColorOutput Green "HelloID (access)group '$group' successfully found: $delegatedFormAccessGroupGuid"
    } catch {
        Write-ColorOutput Red "HelloID (access)group '$group'"
        $_
    }
}
  
  
  
$delegatedFormName = "AD Account - Update details"
$delegatedFormGuid = ""
$delegatedFormCreated = $false
  
try {
    try {
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms/$delegatedFormName")
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false
    } catch {
        $response = $null
    }
  
    if([string]::IsNullOrEmpty($response.delegatedFormGUID)) {
        #Create DelegatedForm
        $body = @{
            name = "$delegatedFormName";
            dynamicFormGUID = "$formGuid";
            isEnabled = "True";
            accessGroups = $delegatedFormAccessGroupGuids;
            useFaIcon = "True";
            faIcon = "fa fa-pencil";
        }  
  
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/delegatedforms")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
  
        $delegatedFormGuid = $response.delegatedFormGUID
        Write-ColorOutput Green "Delegated form '$delegatedFormName' created: $delegatedFormGuid"
        $delegatedFormCreated = $true
    } else {
        #Get delegatedFormGUID
        $delegatedFormGuid = $response.delegatedFormGUID
        Write-ColorOutput Yellow "Delegated form '$delegatedFormName' already exists: $delegatedFormGuid"
    }
} catch {
    Write-ColorOutput Red "Delegated form '$delegatedFormName'"
    $_
}  
  
  
  
$taskActionName = "AD-user-set-attributes-update"
$taskActionGuid = ""
  
try {
    if($delegatedFormCreated -eq $true) {
        #Create Task
  
        $body = @{
            name = "$taskActionName";
            useTemplate = "false";
            powerShellScript = @'
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
'@;
            automationContainer = "8";
            objectGuid = "$delegatedFormGuid";
            variables = @(@{name = "company"; value = "{{form.company}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "department"; value = "{{form.department}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "title"; value = "{{form.title}}"; typeConstraint = "string"; secret = "False"},
                        @{name = "userPrincipalName"; value = "{{form.gridUsers.UserPrincipalName}}"; typeConstraint = "string"; secret = "False"});
        }
        $body = $body | ConvertTo-Json
  
        $uri = ($PortalBaseUrl +"api/v1/automationtasks/powershell")
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -ContentType "application/json" -Verbose:$false -Body $body
        $taskActionGuid = $response.automationTaskGuid
  
        Write-ColorOutput Green "Delegated form task '$taskActionName' created: $taskActionGuid"
    } else {
        Write-ColorOutput Yellow "Delegated form '$delegatedFormName' already exists. Nothing to do with the Delegated Form task..."
    }
} catch {
    Write-ColorOutput Red "Delegated form task '$taskActionName'"
    $_
}