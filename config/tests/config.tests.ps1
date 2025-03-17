return @{
    # ============ WIM TESTS ============
    Wim = @{

        WindowsTests = @(
            [PSCustomObject]@{
                Name            =   "Test Windows Taskbar Contents"
                TestRailCode    =   374768
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Get-AndTestWindowsTaskbarContents}
            },
            [PSCustomObject]@{
                Name            =   "Test Windows Start Menu Contents"
                TestRailCode    =   374769
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Get-AndTestWindowsStartMenuContents}
            },
            [PSCustomObject]@{
                Name            =   "Test Windows App Menu Contents"
                TestRailCode    =   374770
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Get-AndTestWindowsAppMenuContents}
            },
            [PSCustomObject]@{
                Name            =   "Test Windows Licensing"
                TestRailCode    =   374728
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Get-WindowsLicensingAndEvidence}
            },
            [PSCustomObject]@{
                Name            =   "Test Chrome History"
                TestRailCode    =   374722
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ChromeHistory}
            },
            [PSCustomObject]@{
                Name            =   "Test Chrome Bookmarks"
                TestRailCode    =   401173
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ChromeBookmarks}
            },
            [PSCustomObject]@{
                Name            =   "Test Chrome Homepage"
                TestRailCode    =   401174
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ChromeHomepage}
            },
            [PSCustomObject]@{
                Name            =   "Test Windows Update Enabled"
                TestRailCode    =   374730
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-WindowsUpdateEnabled}
            },
            [PSCustomObject]@{
                Name            =   "Test VFC Overlay"
                TestRailCode    =   374734
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Get-VFCOverlay}
            },
            [PSCustomObject]@{
                Name            =   "Test Windows Firewall is Disabled"
                TestRailCode    =   374731
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-WindowsFirewallDisabled}
            },
            [PSCustomObject]@{
                Name            =   "Test Notifications is Disabled"
                TestRailCode    =   374729
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-NotificationsDisabled}
            },
            [PSCustomObject]@{
                Name            =   "Test Installed App And Feature Versions"
                TestRailCode    =   795477
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-InstalledAppAndFeatureVersions}
            },
            [PSCustomObject]@{
                Name            =   "Test Right Click Context Menu Registry Values"
                TestRailCode    =   843435
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-RightClickContextMenuRegistryValues}
            }
        )

        DevicesTests = @(
            [PSCustomObject]@{
                Name            =   "Test Graphics Card Control Pannel"
                TestRailCode    =   374743
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-GraphicsCardControlPannel}
            },
            [PSCustomObject]@{
                Name            =   "Test Matrox Capture Cards Driver"
                TestRailCode    =   374748
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-CaptureCard -CaptureCardManufacturer 'MATROX'}
            },
            [PSCustomObject]@{
                Name            =   "Test Deltacast Capture Cards Driver"
                TestRailCode    =   588212
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-CaptureCard -CaptureCardManufacturer 'deltacast'}
            },
            [PSCustomObject]@{
                Name            =   "Test Audio Cards Driver"
                TestRailCode    =   374749
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-AudioCard}
            },
            [PSCustomObject]@{
                Name            =   "Test Device Manager Driver Versions"
                TestRailCode    =   374755
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-DeviceManagerDriverVersions}
            },
            [PSCustomObject]@{
                Name            =   "Test Problem Drives"
                TestRailCode    =   374742
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ProblemDevices}
            }
        )

        d3InteractionTests = @(
            [PSCustomObject]@{
                Name            =   "Test OS Name Wim Test Suite"
                TestRailCode    =   374766
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-OSName}
            }
        )
    }

    # ============ USB TESTS ============
    USB = @{
        GeneralISOFunctions = @(
            [PSCustomObject]@{
                Name            =   "Test Projects Registry Paths"
                TestRailCode    =   754268
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ProjectsRegPath}
            },
            [PSCustomObject]@{
                Name            =   "Test Machine Name"
                TestRailCode    =   754270
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-MachineName}
            },
            [PSCustomObject]@{
                Name            =   "Test Logs Present Local"
                TestRailCode    =   754271
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ReImageLogs}
            },
            [PSCustomObject]@{
                Name            =   "Test Logs Present Remote"
                TestRailCode    =   767414
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-RemoteReImageLogs}
            },
            [PSCustomObject]@{
                Name            =   "Test Net Adapter Names"
                TestRailCode    =   754273
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-NICNames}
            },
            [PSCustomObject]@{
                Name            =   "Test Audio Cards"
                TestRailCode    =   754277
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-AudioCard}
            },
            [PSCustomObject]@{
                Name            =   "Test D Drive"
                TestRailCode    =   754280
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-DDrive}
            },
            [PSCustomObject]@{
                Name            =   "Test Problem Devices"
                TestRailCode    =   754272
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ProblemDevices}
            },
            [PSCustomObject]@{
                Name            =   "Test Disguised Power Gets Deleted"
                TestRailCode    =   832543
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-CWindowsDisguisedpowerGetsDeleted}
            }
        )

        d3InteractionTests = @(
            [PSCustomObject]@{
                Name            =   "Test OS Name On Redisguise Test Suite"
                TestRailCode    =   754265
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-OSName}
            }
        )
    }

    # ============ R20 TESTS ============
    R20 = @{
        GeneralISOFunctions = @(
            [PSCustomObject]@{
                Name            =   "Test Projects Registry Paths"
                TestRailCode    =   754268
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ProjectsRegPath}
            },
            [PSCustomObject]@{
                Name            =   "Test Machine Name"
                TestRailCode    =   754270
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-MachineName}
            },
            [PSCustomObject]@{
                Name            =   "Test Logs Present Local"
                TestRailCode    =   754271
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ReImageLogs}
            },
            [PSCustomObject]@{
                Name            =   "Test Logs Present Remote"
                TestRailCode    =   767414
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-RemoteReImageLogs}
            },
            [PSCustomObject]@{
                Name            =   "Test Net Adapter Names"
                TestRailCode    =   754273
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-NICNames}
            },
            [PSCustomObject]@{
                Name            =   "Test Audio Cards"
                TestRailCode    =   754277
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-AudioCard}
            },
            [PSCustomObject]@{
                Name            =   "Test D Drive"
                TestRailCode    =   754280
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-DDrive}
            },
            [PSCustomObject]@{
                Name            =   "Test Problem Devices"
                TestRailCode    =   754272
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-ProblemDevices}
            },
            [PSCustomObject]@{
                Name            =   "Test Disguised Power Gets Deleted"
                TestRailCode    =   832543
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-CWindowsDisguisedpowerGetsDeleted}
            }
        )

        d3InteractionTests = @(
            [PSCustomObject]@{
                Name            =   "Test OS Name On Redisguise Test Suite"
                TestRailCode    =   754265
                TestStatus      =   "NOT TESTED"
                TestMessage     =   $null
                PathToImage     =   $null
                TestScriptBlock =   {Test-OSName}
            }
        )
    }
}