# Tanium Deployed Homelab

figureout  deployment of kubernetes 
elastic search 
figure out automating self hosting webserver and pushing content to real website, wizzense.com
look into MDT and pixie booting 
maybe that will be easier than mounting this custom bootable bullshit 

https://help.tanium.com/bundle/ug_provision_cloud/page/provision/preparing_content.html


how does kubernetes and docker play into this?


Win PE add-on required for media creation
  automate download and install of adk and adk add-on
  https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-create-usb-bootable-drive?view=windows-11
    https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install
    Download the ADK 10.1.25398.1 (September 2023):
    ADK 10.1.25398.1 (September 2023)
    Windows PE add-on for the ADK 10.1.25398.1 (September 2023)

- Standard ISOs just might not work for this
  - looks like I need to create a custom WIM in order to boot from ISO and configure the OS

- look into automating container clusters
  
- look into auotmatically getting isos and keys from https://my.visualstudio.com/
- opentofu uses dependencies to control orrder of operations

```tofu
# Declare the hyperv_vhd resource for the PrimaryControlNode VHD
resource "hyperv_vhd" "PrimaryControlNode-vhd" {
  depends_on = [hyperv_network_switch.Lan]

  path = "C:\\HyperV\\VMs\\PrimaryControlNode\\PrimaryControlNode.vhdx"
  size = 60737421312 # Size in bytes, make sure this is divisible by 4096
}
```


  - https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install - need this to work on the isos nand sysprep
    - look into automating download and install

run this to prepare the .ppkg, which you then copy to the PCN VM
C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Imaging and Configuration Designer

```scp
scp .\tanium_homelab_automation.zip administrator@192.168.87.134:C:\
```

```dism
PS C:\tanium_homelab_automation\tanium_homelab_automation> dism /Online /Add-ProvisioningPackage /PackagePath:tanium_homelab_automation.ppkg

Deployment Image Servicing and Management tool
Version: 10.0.26100.1

Image Version: 10.0.26100.1

The operation completed successfully.
```

prepare tanium client[https://help.tanium.com/bundle/ug_client_cloud/page/client/os_imaging_windows.html]

- look into using opentofu for Infrastructure as Code[https://opentofu.org/docs/intro/install/standalone/]
  - Looks like opentofu is supposed to be installed on the hypervisor - so this will be interesting for installing control node vms vs vms on the lab hypervisor -- might be two layers here.
  - <https://library.tf/providers/taliesins/hyperv/latest> -

    - 
    - tried running this on my dom with hyperv installed and then tried running the plan, but couldnt not connect, trying locally
      - revisit this to use remote hyper-v hosts.

    - [x] successfully deployed PrimaryControlNode VM with opentofu 
      - [ ] successfully destroyed deployed infrastructure
      - [ ] now I need to figure out the unattended installation. is this ansible, or this could be provision for other VMs -- in this case, this endpoint
        is to become the satellite provision endpoint so i need the unattended install that way.
        tofu init
        tofu import hyperv_iso_image.Win11_23H2_English_x64v2 E:\Data\Win11_23H2_English_x64v2.iso
        tofu plan -out pcn-plan.conf
        tofu apply pcn-plan.conf
        tofu destroy -target=hyperv_machine_instance.PrimaryControlNode
      - [] requires prep =  need to make sure to prep hyper-v host with setup script to work with tailsins/hyperv: .\tailsins-prepare-hypervhost.ps1

    - ```tofu


          The resources that were imported are shown above. These resources are now in
          your OpenTofu state and will henceforth be managed by OpenTofu.
      ```
automate handling of resources that already exist:

```powershell
PS C:\Users\alexa\OneDrive\0. Lab\opentofu\my-infra> tofu apply "pcn-plan.conf"
hyperv_network_switch.Lan: Creating...
hyperv_vhd.PrimaryControlNode-vhd: Creating...
╷
│ Error: a resource with the ID "C:\\HyperV\\VMs\\PrimaryControlNode\\PrimaryControlNode.vhdx" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "hyperv_vhd" for more information.
│  terraform import hyperv_vhd.<resource name> C:\HyperV\VMs\PrimaryControlNode\PrimaryControlNode.vhdx
│
│   with hyperv_vhd.PrimaryControlNode-vhd,
│   on tofu-vm-primarycontrolnode.tf line 2, in resource "hyperv_vhd" "PrimaryControlNode-vhd":
│    2: resource "hyperv_vhd" "PrimaryControlNode-vhd" {
│
╵
╷
│ Error: a resource with the ID "DMZ" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "hyperv_network_switch" for more information.
│  terraform import hyperv_network_switch.<resource name> DMZ
│
│   with hyperv_network_switch.Lan,
│   on tofu-vm-primarycontrolnode.tf line 8, in resource "hyperv_network_switch" "Lan":
│    8: resource "hyperv_network_switch" "Lan" {
│

hyperv_network_switch.Lan: Creation complete after 11s [id=DMZ]
╷
│ Error: a resource with the ID "C:\\HyperV\\VMs\\PrimaryControlNode\\PrimaryControlNode.vhdx" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "hyperv_vhd" for more information.
│  terraform import hyperv_vhd.<resource name> C:\HyperV\VMs\PrimaryControlNode\PrimaryControlNode.vhdx
│
│   with hyperv_vhd.PrimaryControlNode-vhd,
│   on tofu-vm-primarycontrolnode.tf line 2, in resource "hyperv_vhd" "PrimaryControlNode-vhd":
│    2: resource "hyperv_vhd" "PrimaryControlNode-vhd" {
```

- [] automate cleanup if an instance fails and is no longer recognized for whatever reason (just had to manually remove the VM and Vswitch)

```tofu
terraform {
  required_providers {
    hyperv = {
      source = "taliesins/hyperv"
      version = "1.2.1"
    }
  }
}

provider hyperv {
  # Configuration options
}
```

## Configuration options

- look into using GoLang[https://go.dev/doc/install]
- look into ansible for per endpoint configuration management (secondary to using tanium automate / enforce/ etc)
- Look into CI/CD with GitHub Actions

## Quick Start

1. Download and clone the repo
2. Run kickstart.ps1

## Guiding Principles

Painstaklingly document everything
Painstakingly automate everything.
Everything.
From file downloads and .iso downloads to directory structure on Primary/ Work PCs for storing configurations and VMs, to VM deployment and configuration and management.

## Definitions

Primary PC = Home PC - recommended candidate for as primary hypervisor for the primary control node

Primary Control Node = VM on primary PC, provisioned for Tanium Cloud.

Work PC = Really, this is a secondary PC, but we're assuming you have hardware provided by your company. This is what we will use for redundancy/ failover/ additional access point -- will also run as a hypervisor and clustered with the Primary PC (Home PC).

## Wishlist

- The primary purpose is for it to be your control node for the deploying your lab useing Provision from Tanium Cloud. We do not need it to be running an available all the time, only when we want to re-provision our baremetal DOM or lab hardware. We will take care to automate every possible piece, from preparing an image, uploading the image to Tanium, creating a control node VM, instaling the Tanium Client, creating a satellite, creating a provision bundle, (leverage API) and deploying it from the satellite VM to the DOM/ lab hardware, which will then be Windows Server w/ Hyper-V, install Tanium, use automat/deploy/ ETC to copy .exes/.isos/local tooling and scripts for automating VM deployments (automate VM deployment of TanOS (look into using shell scripts for auto configuration fo TanOS and installation of Tanium Server) and use custom tags with packages that run the scripts/tooling that configures the VMs) Automate Domain Controller, pfsense, aTanium, and test endpoints on lab hardware.

I want to auto deploy a full mini-infrastructure

incorporate DR and redundancy, for example, if you have 2 or 3 bare metal machines.

Cluster hyper-v on two physical machines (where lab is deployed on third as main lab hypervisor), with high availability control node VMs for deplyoing labs.

will try to use AI, python/powershell/API for every single step
Will use VM images/ VHDs/ templates if sensible. Ideally, this will be plug and play, so it's not relying on images /isos being updated in order for it to work.

so, incorporate ease of automating the creation of the control node VM with any OS and config file/settings

allow plugging in desired server/client OS.isos, etc.

Allow plugging in of specific Tanium Clients/ Tanium Server / Tan OS versions

Guided setup of Patch to patch everything (automate config w/ API as much as possible)

Guided setup of Deploy to deploy desired apps (automate config w/ API as much as possible)

guided setup of Enforce (configuration management)

guided setup of internetworking from Tanium Cloud > Control Node on primary PC

autoconfig of Windows server roles > ADDS, DNS, DHCP, ADCS

autoconfig soap certs creation and configuration

autoconfig hyper-v checkpoints

autoconfig backups on baremetal Primary/Work PCs for control node VMs

add primary PC to your lab tanium instance for additional and mirror configurations from Patch/ Deploy/ Enforce.

Have a redundant ldap/dns/dhcp running on Linux that I can fail over configs from Windows

automate deployment of WAC V2 on Primary PC, Work PC, and Lab hypervisor.
