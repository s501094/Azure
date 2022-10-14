<#
.SYNOPSIS  
 Update Management Center Sku compliance check
.DESCRIPTION  
 Update Management Center Sku, offer, Publisher compliance check
.EXAMPLE  
.\UMC_VM_Sku_check.ps1 
Version History  
v1.3   - beta Release  
#>

# ------------------Execution Entry point ---------------------#


[string] $FailureMessage = "Failed to execute the command"
[int] $RetryCount = 3 
[int] $TimeoutInSecs = 20
$RetryFlag = $true
$Attempt = 1
do
{

    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

        Add-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
        
        Write-Output "Successfully logged into Azure subscription using Az cmdlets..."

        $RetryFlag = $false
    }
    catch 
    {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."

            $RetryFlag = $false

            throw $ErrorMessage
        }

        if ($Attempt -gt $RetryCount) 
        {
            Write-Output "$FailureMessage! Total retry attempts: $RetryCount"

            Write-Output "[Error Message] $($_.exception.message) `n"

            $RetryFlag = $false
        }
        else 
        {
            Write-Output "[$Attempt/$RetryCount] $FailureMessage. Retrying in $TimeoutInSecs seconds..."

            Start-Sleep -Seconds $TimeoutInSecs

            $Attempt = $Attempt + 1
        }   
    }
}
while($RetryFlag)

$subID = "c9cec887-c8df-48c6-9889-8ac3f60eabc7"
$TenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"
set-azcontext -Subscription $subID -Tenant $TenantId

#-------------------------PULL VM List From Subscription--------------------------------#

$VMList = get-azvm | select name, ResourceGroupName, Location

#------------------------- Running python file to pull lastest supported os's from web and output to csv --------------------------------#
#
# Before running, ensure that requests, pandas, beautifulsoup4, and lxml are all installed
#
#Move-Item $env:USERPROFILE\Desktop\testing\Supported_OS_data.py $env:USERPROFILE

python.exe "$env:USERPROFILE\Supported_OS_data.py"



#-------------------------PULL Sku, Publisher, Offer From Virtual Machine --------------------------------#
$table = New-Object System.Data.Datatable
[void]$table.Columns.Add("Name")
[void]$table.Columns.Add("Publisher")
[void]$table.Columns.Add("Offer")
[void]$table.Columns.Add("sku")
[void]$table.Columns.Add("AssessmentMode")
[void]$table.Columns.Add("supported")
foreach($vm in $VMList){
    $SupportList = Import-Csv -Path "C:\UMC\Supported_OS_data.csv"

    if(((Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).StorageProfile.ImageReference.Offer) -contains "windows"){
        
        $AssessmentMode = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).OSProfile.WindowsConfiguration.PatchSettings.PatchMode
    }else{
        $AssessmentMode = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).OSProfile.LinuxConfiguration.PatchSettings.AssessmentMode
        }

    if($AssessmentMode -eq $null){
        $AssessmentMode = "No Assessment Set"
    }
    $Name = $vm.Name
    $Publisher = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).StorageProfile.ImageReference.Publisher
    $Offer = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).StorageProfile.ImageReference.Offer
    $Sku = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).StorageProfile.ImageReference.Sku
    try{
        if((Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $VM.Name).StorageProfile.ImageReference.Sku -in $SOSLists.Sku){
        $supported = "supported"
        
    }else{
        $supported = "Not Supported"
        }
    }catch{
        
        Write-Warning "Unable to test sku"
        }

    
    [void]$table.Rows.Add($Name,$Publisher,$Offer, $Sku,$AssessmentMode,$supported)
}
$table | FT -AutoSize

#$pythonFile = $env:USERPROFILE\'Supported_OS_data.py'
$destination = 'C:\UMC'
Remove-Item $pythonFile -Force
Get-ChildItem -Path $Destination -Recurse | Remove-Item -force -recurse
Remove-Item $destination -Force








