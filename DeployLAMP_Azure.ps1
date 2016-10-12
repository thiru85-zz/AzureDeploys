﻿# Build a LAMP Stack VM on Azure using the BitNami image
# Author: Thirumalai Aiyalu (thiru85@yahoo.com)
# Version: 1.0
#
#
#
# Feel free to change variables and options as you see fit

##################################################################################

$vmname="<NAME>" #Name of VM

#This is using the classic storage account and not the RM Storage Account
$storAcc=Get-AzureStorageAccount
$diskName=$vmname+"_OSDisk"
$vmBlobPath ="vhds/"+$vmname+"_OSDisk.vhd"
$osDiskURI = $storAcc.Endpoints[0]+$vmBlobPath

#West US is easier
$loc = "westus"
$rgName=Get-AzureRmResourceGroup | ?{$_.ResourceGroupName -like "<PRE-EXISTING ResourceGroupName>*"}

#Extracting the VM Image and the SKU/Offer
$imgOffer=Get-AzureRmVMImageOffer -Location westus -PublisherName bitnami | ? {$_.Offer -like "lamp*"}
$lampstackSKU=Get-AzureRmVMImageSku -Location westus -PublisherName bitnami -Offer $imgOffer.Offer

#This script deploys into a pre-existing VNet and ResourceGroup so feel free to change this if needed.
# A main VNET with a /16 subnet exists
$vnet=Get-AzureRmVirtualNetwork

#Create new NIC for the new VM
$nicName = $vmname+"_nic01"
$nic=New-AzureRmNetworkInterface -Name $nicName -ResourceGroupName $rgName.ResourceGroupName -Location $loc -SubnetId $vnet.Subnets[1].Id

$adminCred=Get-Credential -Message "Name and Password of new VM, please enter" #Self-explanatory

#Setting up VM Configuration such as size, image, VHD path etc.
$vmConfig = New-AzureRmVMConfig -VMName $vmname -VMSize "Basic_A1"
$vmConfig = Set-AzureRmVMOperatingSystem -VM $vmConfig -Linux -ComputerName $vmname -Credential $adminCred
$vmConfig = Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName $lampstackSKU.PublisherName -Offer $imgOffer.Offer -Skus $lampstackSKU.Skus -Version latest
$vmConfig = Add-AzureRmVMNetworkInterface -vm $vmConfig -Id $nic.Id
$vmConfig = Set-AzureRmVMOSDisk -VM $vmConfig -Name $diskName -VhdUri $osDiskURI -CreateOption FromImage

#After all the above prep work, we finally build the VM
New-AzureRmVM -ResourceGroupName $rgName.ResourceGroupName -Location $loc -VM $vmConfig

