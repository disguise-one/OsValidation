return @{
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
    }
    # USB = @{
    #     WindowsTests = @(
    #         [PSCustomObject]@{
    #             Name            =   "Test Windows Taskbar Contents"
    #             TestRailCode    =   374768
    #             TestStatus      =   "NOT TESTED"
    #             TestMessage     =   $null
    #             PathToImage     =   $null
    #             TestScriptBlock =   {Get-AndTestWindowsTaskbarContents}
    #         }
    #     )
    # }

    
    # R20 = @{
    #     WindowsTests = @(
    #         [PSCustomObject]@{
    #             Name            =   "Test Windows Taskbar Contents"
    #             TestRailCode    =   374768
    #             TestStatus      =   "NOT TESTED"
    #             TestMessage     =   $null
    #             PathToImage     =   $null
    #             TestScriptBlock =   {Get-AndTestWindowsTaskbarContents}
    #         }
    #     )
    # }
}