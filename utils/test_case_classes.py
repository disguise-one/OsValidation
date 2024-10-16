# This is a testCase class we can use to create objects as currently the system just output's a string

class TestCase:
    testCode = ""   # <- The test case ID
    testName = ""
    testResult = ""
    testResultBool = ""
    testResultMessage = ""
    testStatus = 100

    def __init__(self, testCode, testName, testResult):
        self.testCode = testCode
        self.testName = testName
        self.testResult = testResult
        self.testResultBool = True if (testResult == "PASSED") else False
        self.testResultMessage = ""
        self.testStatus = 3

    
    # Specific methods
    # This method returns the formatted string
    def formatOutputString(self):
        return "| " + self.testCode + " | " + self.testName + ": " + self.testResult
    
    # This method then prints the formatted string
    def printFormattedResults(self):
        print(self.formatOutputString())
    
    # Updates the result bool
    def updateResultBool(self):
        self.testResultBool = True if (self.testResult == "PASSED") else False
        

    def updateStatusCode(self):
        match self.get_testResult():
            case "PASSED":
                self.set_testStatusCode(1)
            case "BLOCKED":
                self.set_testStatusCode(2)
            case "UNTESTED":
                self.set_testStatusCode(3)
            case "RETEST":
                self.set_testStatusCode(4)
            case "FAILED":
                self.set_testStatusCode(5)
            case _:
                self.set_testStatusCode(6)

    
    # Getter and Setter methods
    # Getter methods:
    def get_testCode(self):
        return self.testCode
        
    def get_testName(self):
        return self.testName
     
    def get_testResult(self):
        return self.testResult
        
    def get_testResultBool(self):
        return self.testResultBool
    
    def get_testResultMessage(self):
        return self.testResultMessage
    
    def get_testStatusCode(self):
        return self.testStatus
    
    # Setter methods:
    def set_testCode(self, testCode):
        self.testCode = testCode

    def set_testName(self, testName):
        self.testName = testName
    
    def set_testResult(self, testResult):
        self.testResult = testResult
        self.updateResultBool()
        self.updateStatusCode()
        
    def set_testResultBool(self, testResultBool):
        self.testResultBool = testResultBool

    def set_testResultMessage(self, testResultMessage):
        self.testResultMessage = testResultMessage

    def set_testStatusCode(self, statusCode):
        self.testStatus = statusCode

        