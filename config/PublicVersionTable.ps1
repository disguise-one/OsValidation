[PSCustomObject]@{
    OSFamily = "vx3"     #JM: This field was previously called 'Model' but has been renamed Model for clarity (TO DO Update scripts accordingly)
    OSReleaseName = "24Q3"   #JM: This field has been added  (TO DO Update scripts accordingly)
    DateExported = "11/11/2024 16:33:22"
    PackageVersions = [PSCustomObject[]]@(
            [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Motherboard Chipset Driver: SPC621_2L2T"
        chocoPackageHandle="chipset_SPC621_2L2T"
        sharedPackageHandle="Intel Chipset"   #This one is gold dust
        chocoPackageVersion="10.1.18807.8279"
        publicPackageVersion="10.1.26.8"
        osValidationPackageVersion="10.1.26.8"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Intel Network Adapter for X710, X722 & I210 cards"
        chocoPackageHandle="intel_network"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="26.8"
        publicPackageVersion="26.8"
        osValidationPackageVersion="26.8.0.1"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Intel Network Adapter Driver for I710&I720"
        chocoPackageHandle="Intel_network_x710"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="26.9"
        publicPackageVersion="26.9"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="NVIDIA Driver and Software"
        chocoPackageHandle="nvidia_feature"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="551.52.0"
        publicPackageVersion="551.52.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Mellanox Driver & Rivermax Runtime (all mlx NICs)"
        chocoPackageHandle="mellanox_netof2"
        sharedPackageHandle="Mellanox NIC Adapter Driver"   #This one is gold dust
        chocoPackageVersion="2.90.50010"
        publicPackageVersion="2.90.25506"
        osValidationPackageVersion="2.90.25506"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Deltacast Certificate"
        chocoPackageHandle="deltacast_cert"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="3.0"
        publicPackageVersion="3.0"
        osValidationPackageVersion="none"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="Deltacast 3G and 12G Driver & Shared App DLLs"
        chocoPackageHandle="deltacastvd_all"
        sharedPackageHandle="Deltacast Driver"   #This one is gold dust
        chocoPackageVersion="6.22.01"
        publicPackageVersion="6.22.06"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="RME audio"
        chocoPackageHandle="rmeaudio"
        sharedPackageHandle="RME Audio"   #This one is gold dust
        chocoPackageVersion="4.38"
        publicPackageVersion="4.3.8.0"
        osValidationPackageVersion="4.3.8.0"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="FTDI USB Config - Support for BackPlane v1 and v2"
        chocoPackageHandle="ftdi"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="2.12.36.4"
        publicPackageVersion="2.12.36.4"
        osValidationPackageVersion="wont show in device manager itself - but will allow you to see ftdi backplane chips in device manager"
    }, 
    [pscustomobject]@{
        category="01-Drivers"
        friendlyName="HDMI VFC Card Overlay Driver"
        chocoPackageHandle="VFC_HDMI_Overlay"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Mellanox Firmware Tools"
        chocoPackageHandle="mellanox_mft"
        sharedPackageHandle="Mellanox WinMFT"   #This one is gold dust
        chocoPackageVersion="4.20.0.34"
        publicPackageVersion="4.20.0.34"
        osValidationPackageVersion="4.20.0.34"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Open SLP"
        chocoPackageHandle="openslp"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="3.0.0"
        publicPackageVersion="3.0.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Visual C++ Essential Update 1 of 4 (Online)"
        chocoPackageHandle="vcredist2010"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Visual C++ Essential Update 2 of 4 (Online)"
        chocoPackageHandle="vcredist2013"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Visual C++ Essential Update 3 of 4 (Online)"
        chocoPackageHandle="vcredist2015"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Visual C++ Essential Update 4 of 4 (Online)"
        chocoPackageHandle="vcredist140"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="VIMBA Camera Image SDK - for Omnical feature in d3"
        chocoPackageHandle="vimba"
        sharedPackageHandle="Vimba"   #This one is gold dust
        chocoPackageVersion="2.1"
        publicPackageVersion="2.1.3"
        osValidationPackageVersion="2.1.3"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="VimbaX Camera Image SDK - for Omnical feature in d3"
        chocoPackageHandle="vimbax"
        sharedPackageHandle="vimbaX"   #This one is gold dust
        chocoPackageVersion="2023.4.0.2776"
        publicPackageVersion="2023.4.0.2776"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="d3 installer"
        chocoPackageHandle="d3"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="26.3.1.175532"
        publicPackageVersion="26.3.1.175532"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Google Chrome (Online)"
        chocoPackageHandle="googlechrome"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="k-litecodecpackmega (Online)"
        chocoPackageHandle="k-litecodecpackmega"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion=""
        publicPackageVersion=""
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Deltacast dCare"
        chocoPackageHandle="deltacast_dcare"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.13"
        publicPackageVersion="1.12.4"
        osValidationPackageVersion="1.12.4"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="Deltacast dScope"
        chocoPackageHandle="deltacast_dscope"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.9.0"
        publicPackageVersion="1.9.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="NVIDIA SDK (Ampere) (For Ampere Range GPUs)"
        chocoPackageHandle="Nvidia_VideoSDK_Ampere"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="0.7.2"
        publicPackageVersion="0.7.2"
        osValidationPackageVersion="0.7.2"
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="NVIDIA ARSDK (Ampere) (For Ampere Range GPUs)"
        chocoPackageHandle="Nvidia_ARSDK_Ampere"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="0.8.2"
        publicPackageVersion="0.8.2"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="OpenSSH"
        chocoPackageHandle="openssh"
        sharedPackageHandle="OpenSSH"   #This one is gold dust
        chocoPackageVersion="9.5.0"
        publicPackageVersion="9.5.0"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="NotePad++"
        chocoPackageHandle="notepadplusp"
        sharedPackageHandle="NotePad++"   #This one is gold dust
        chocoPackageVersion="8.6.7"
        publicPackageVersion="8.6.7"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="02-Software"
        friendlyName="7Zip"
        chocoPackageHandle="7Zip"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="24.8.0"
        publicPackageVersion="24.08"
        osValidationPackageVersion="24.08"
    }, 
    [pscustomobject]@{
        category="03-Rackmount"
        friendlyName="rackmount_ooshutup10_automatic"
        chocoPackageHandle="rackmount_ooshutup10_automatic"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="03-Rackmount"
        friendlyName="rackmount_ExtraUtilities"
        chocoPackageHandle="rackmount_extrautilities"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.5"
        publicPackageVersion="1.5"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="03-Rackmount"
        friendlyName="rackmount_theme_w10"
        chocoPackageHandle="rackmount_theme_w10"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="03-Rackmount"
        friendlyName="rackmount_chrome_prefs"
        chocoPackageHandle="rackmount_chrome_prefs"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion="unknown"
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Remove Windows Action Centre"
        chocoPackageHandle="reg_actioncentremessages"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Legacy Registry edits required for old models"
        chocoPackageHandle="reg_d3regsettings"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_folderOption"
        chocoPackageHandle="reg_folderoption"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Disable Win 8 'Charms' Menu"
        chocoPackageHandle="reg_nocharms"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Hide Recycle Bin From Desktop"
        chocoPackageHandle="reg_recyclebin"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Disable Windows UAC"
        chocoPackageHandle="reg_disableUAC"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Disable most Win10 Notifications"
        chocoPackageHandle="reg_notifications"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_AutoTimeZone"
        chocoPackageHandle="reg_autotimezone"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Disable 'Edge' Search Bar on Desktop"
        chocoPackageHandle="reg_DisableMicrosoftEdgeDesktopSearchBar"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Disable Windows Feed"
        chocoPackageHandle="reg_DisableWindowsFeeds"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Non-Reg Config Change to Disbale USB Selective Suspend"
        chocoPackageHandle="pwcfg_DisableUSBSelectiveSuspend"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0"
        publicPackageVersion="1.0"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to remove The 'Firewall Disabled' Toast "
        chocoPackageHandle="reg_HideWindowsSecurityNotification"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to turn Lock Screen Black (IMPORTANT)"
        chocoPackageHandle="reg_fixaccentcolour"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_noInterestsBar"
        chocoPackageHandle="reg_nointerestsbar"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.1.1"
        publicPackageVersion="1.1.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_PoliciesForWin10+"
        chocoPackageHandle="reg_win10policies"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.3.0"
        publicPackageVersion="1.3.0"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: Tweaks linked to d3 user account"
        chocoPackageHandle="reg_user"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.2.1"
        publicPackageVersion="1.2.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_disableWindowsUpdateAccess"
        chocoPackageHandle="reg_disablewindowsupdateaccess"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_StopWindowsUpdate"
        chocoPackageHandle="reg_stopwindowsupdate"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_renderstreamFolder"
        chocoPackageHandle="reg_renderstreamFolder"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: Disable Full Screen Optimizations on d3.exe"
        chocoPackageHandle="reg_DisableFullScreenOptimisations"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak to Update Win 11 Properties UI to look like Win 10"
        chocoPackageHandle="reg_window10propertiesui"
        sharedPackageHandle="reg_window10propertiesui"   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }, 
    [pscustomobject]@{
        category="04-Registry"
        friendlyName="Reg Tweak: reg_DisableChromeSignIn"
        chocoPackageHandle="reg_DisableChromeSignIn"
        sharedPackageHandle=""   #This one is gold dust
        chocoPackageVersion="1.0.1"
        publicPackageVersion="1.0.1"
        osValidationPackageVersion=""
    }
    )
}