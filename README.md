<!-- Description -->
## Description
This HelloID Service Automation Delegated Form provides AD user account update details functionality. The following options are available:
 1. Search and select the target AD user account
 2. Show basic AD user account attributes of selected target user
 3. Enter new values for the following AD user account attributes; Company, Department and Title
 5. AD user account attributes are updated with new values
 
<!-- TABLE OF CONTENTS -->
## Table of Contents
* [Description](#description)
* [All-in-one PowerShell setup script](#all-in-one-powershell-setup-script)
  * [Getting started](#getting-started)
* [Post-setup configuration](#post-setup-configuration)
* [Manual resources](#manual-resources)


## All-in-one PowerShell setup script
The PowerShell script "createform.ps1" contains a complete PowerShell script using the HelloID API to create the complete Form including user defined variables, tasks and data sources.

 _Please note that this script asumes none of the required resources do exists within HelloID. The script does not contain versioning or source control_


### Getting started
Please follow the documentation steps on [HelloID Docs](https://docs.helloid.com/hc/en-us/articles/360017556559-Service-automation-GitHub-resources) in order to setup and run the All-in one Powershell Script in your own environment.

 
## Post-setup configuration
After the all-in-one PowerShell script has run and created all the required resources. The following items need to be configured according to your own environment
 1. Update the following [user defined variables](https://docs.helloid.com/hc/en-us/articles/360014169933-How-to-Create-and-Manage-User-Defined-Variables)
<table>
  <tr><td><strong>Variable name</strong></td><td><strong>Example value</strong></td><td><strong>Description</strong></td></tr>
  <tr><td>ADusersSearchOU</td><td>[{ "OU": "OU=Disabled Users,OU=HelloID Training,DC=veeken,DC=local"},{ "OU": "OU=Users,OU=HelloID Training,DC=veeken,DC=local"},{"OU": "OU=External,OU=HelloID Training,DC=veeken,DC=local"}]</td><td>Array of Active Directory OUs for scoping AD user accounts in the search result of this form</td></tr>
</table>

## Manual resources
This Delegated Form uses the following resources in order to run

### Powershell data source 'AD-user-generate-table-wildcard-extended'
This Powershell data source runs an Active Directory query to search for matching AD user accounts. It uses an array of Active Directory OU's specified as HelloID user defined variable named _"ADusersSearchOU"_ to specify the search scope. This data source returns additional attributes the receive the current values for company, department and title.

### Powershell data source 'AD-user-generate-table-attributes-extended'
This Powershell data source runs an Active Directory query to select an extended list of user attributes of the selected AD user account.  

### Delegated form task 'AD-user-set-attributes-update'
This delegated form task will update the account attributes of the selected AD user account.
