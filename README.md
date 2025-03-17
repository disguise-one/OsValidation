This is a new and improved version of the OSvalidation repo!

Changelog:
    -   Removed all python. Refactored everything to use powershell

    +   New method of interacting with TestRailAPI - PSTestrail

    +   Now required information is stored in Global:OSValdiationConfig, so nothing needs to be passed in via arguments to individual tests
                Note: Unless you want to! If you do please make sure that the parameter/variable is accessable from the script when it is called, IE: it is a valid variable from inside "Start-TestRailTestRun"'s scope. You are adding the parameter to the config file's scriptblock, so it is essentially copy and pasted into that function. So, as long as the variable is valid inside Start-TestRailTestRun's scope, it will work.

    +   The tests are also now in config files, making adding a new test really easy:
        |-> You create the function you want to use in powershell
        ˈ-> You add a test object to the config/tests/config.tests.ps1 file, to the test group and test family you want. Add the testrail code and put your function in.
            Simple!



Note for developers: Please still NEVER UPLOAD THE CONFIG.LOCAL TO GITHUB!

        

