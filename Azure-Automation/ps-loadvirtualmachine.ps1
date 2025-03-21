# Authenticate with managed identity (if running in Azure Automation)
Connect-AzAccount -Identity

# Set variables
$subscriptionId = "your-subscription-id""
$resourceGroupName = "rg-redhatautomation"
$vmName = "testvm"
$location = "your-region" # e.g., "East US", "West Europe"
$galleryName = "gallery"
$imageDefinitionName = "definition-main"
$imageVersion = "0.0.1"
$adminUsername = "your username"
$adminPassword = "" | ConvertTo-SecureString -AsPlainText -Force
$vmSize = "Standard_B2as_v2"
$virtualnetworkName = "vnet-test"

# Select the subscription
Select-AzSubscription -SubscriptionId $subscriptionId

# Check if the VM exists
$vm = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue

if ($vm) {
    # Get the NIC and Disk associated with the VM
    $nicId = $vm.NetworkProfile.NetworkInterfaces.Id
    $osDiskName = $vm.StorageProfile.OsDisk.Name

    # Delete the VM
    Remove-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -Force

    # Delete the NIC
    $nicName = (Get-AzResource -ResourceId $nicId).Name
    Remove-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name $nicName -Force

    # Delete the OS Disk
    Remove-AzDisk -ResourceGroupName $resourceGroupName -DiskName $osDiskName -Force

    Write-Output "Deleted existing VM, NIC, and Disk."
} else {
    Write-Output "VM does not exist."
}

# Get the image version
$image = Get-AzGalleryImageVersion -ResourceGroupName $resourceGroupName -GalleryName $galleryName -GalleryImageDefinitionName $imageDefinitionName -Name $imageVersion

# Create the VM configuration
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize -SecurityType "TrustedLaunch" |
  Set-AzVMOperatingSystem -Linux -ComputerName $vmName -Credential (New-Object PSCredential ($adminUsername, $adminPassword)) |
    Set-AzVMSourceImage -Id $image.Id |
    Add-AzVMNetworkInterface -Id (New-AzNetworkInterface -ResourceGroupName $resourceGroupName -Name "$vmName-nic" -Location $location -SubnetId (Get-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Name "$virtualnetworkName").Subnets[0].Id).Id

# Create the VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig

# Start the VM
# Start-AzVM -ResourceGroupName "$resourceGroupName" -Name "$vmName"