Connect-AzAccount -Identity # Authenticate with managed identity (if running in Azure Automation)

# Set variables
$subscriptionId = "your-subscription-id" # Subscription ID where the VM will be created
$resourceGroupName = "your-resource-group-name" # Resource group name where the VM will be created
$vmName = "your-vm-name" # Name of the VM to be created
$location = "your-region" # e.g., "East US", "West Europe"
$galleryName = "gallery" # Name of the Shared Image Gallery
$imageDefinitionName = "definition-main" # Name of the image definition in the Shared Image Gallery
$imageVersion = "0.0.1" # Version of the image to be used
$adminUsername = "username" # Admin username for the VM
$adminPassword = "" | ConvertTo-SecureString -AsPlainText -Force # Admin password for the VM (use a secure method to store and retrieve passwords)
$vmSize = "Standard_B2as_v2" # Example VM size
$virtualnetworkName = "vnet-test" # Example virtual network name

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

# Last Updated: 2025-03-21