# QualyfiHubAndSpoke
Welcome to my project.
In this project I have created a hub and spoke landing zone with multiple spokes.

To use this template please run the following command to connect to Azure with an authenticated account:
```
Connect-AzAccount
```
Once connected please run the following code to deploy the template:
```
.\deploy.ps1
```
To check that after deployment your backup is correctly woring use:
```
Get-AzRecoveryservicesBackupJob
```

