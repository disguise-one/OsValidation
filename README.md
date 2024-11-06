A
OS Validation Automated Test

This Python script is designed for performing various validation checks on a Windows operating system. It checks different aspects such as Windows settings, file handling, device configurations, and interactions with a D3 system.

For more detailed description check the wiki: https://github.com/disguise-one/OsValidation/wiki


The OSConfig.JSON is used to allow Script based configuration: DisguisedPower location, username to interact with testrail etc...

Note to developers:
Please leave main in a status that anyone can download and run. This means ENSURING you havent uploaded your UserCredentials.local.json (it should be added to .gitignore but just check you havent staged it), setting first_run to true, and enabling all tests that are ready for use.

