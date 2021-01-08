#############################################
# Test script to run odo java-openliberty stack
# in guithub actions environment
###############################################
import os
import subprocess
import sys
import time

os.system("echo Current directory")
os.system("pwd")

# Function to test the health endpoint
def testHealth(urlList):
     httpURL = getHttpURL(urlList)
     if httpURL:
         print("httpURL not empty")
         liveURL = httpURL + "/health/live"
         readyURL = httpURL + "/health/ready"
         print("live URL = ", liveURL)
         print("ready URL = ", readyURL)
         # lets give the server time to start
         time.sleep(60)
         curlResults = subprocess.run(["curl", liveURL],
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
         print("Health URL check results", curlResults.stdout, "\nError =", curlResults.stderr, " RC =", curlResults.returncode)
     else:
         print("Http URL is empty")

# function to return the HTTP URL for the application

##### TODO - better way to get url??
def getHttpURL(urlList):
    print("Parsing HTTP request from ", urlList)
    http = ""
    httpFound = False
    if len(urlList) >= 2:
        httpRequest = urlList[2].find("http")
        if httpRequest >= 0:
            print("getHttpURL http request = ", httpRequest)
            li = urlList[2].split(" ")
            for i in li:
                if i.find("http") >=0  and not httpFound:
                    http = i
                    httpFound = True
                elif i and httpFound:
                    http = http + ":" + i
                    break
            if http:
                print("Http root = ", http)
        else:
            print("Http URL not provided")
    return http

# check the odo log and look for failed tests
def checkTestResults(logData):
    print("begin checkTestResults")
    failures = 0
    errors = 0
    skipped = 0
    for i in logData:
        if i.find("[INFO] Tests run:") >=0:
            list = i.split(",")
            for result in list:
                if result.find("Failures:") >= 0:
                    if result.find("0") < 0:
                        failures = failures + 1
                elif reseult.find("Errors") >= 0:
                    if result.find("0") < 0:
                        errors = errors + 1
                elif result.find("Skipped") >= 0:
                    if result.find("0") < 0:
                        skipped = skipped + 1

            if failures or errors or skipped:
                print("Test Failure")
            else:
                print("Test Completed successfully")
    return failures + errors + skipped

# Delete the odo project on error or successful completion.
def deleteProject():
    processResults = subprocess.run(["odo","delete"],stdout=subprocess.PIPE,
                               stderr=subprocess.PIPE, text=True)

# Run command line and return results
def runCommand(command):
    print ("Running: ", command)

    processResults = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    print(processResults.stderr, processResults.stdout)

    if (processResults.returncode != 0):
        print("Error when processing command: ", command)

        deleteProject()
        sys.exit(processResults.returncode)
    
    return processResults.stderr + processResults.stdout


# ------- MAIN ------

#### debugging.... remove these commands:
runCommand(["ls", "-al"])
runCommand(["pwd"])
runCommand(["ls", "-al", "/"])
runCommand(["grep", ])

#### debugging .....
runCommand(["kubectl", "version"])

# Added here to clean up minikube environment
# this was suggested to allow the ingress to install and run successfully
runCommand(["minikube", "delete"])

runCommand(["minikube", "start"])

# Enable ingress addon in minikube
runCommand(["minikube", "addons", "enable", "ingress"])
runCommand(["kubectl", "get", "pods", "-n", "kube-system"])

# Get minikube URL
output = runCommand(["minikube", "ip"])
url = output.strip() + ".nip.io"
print("Minikube URL = ", url)
         
# Clone git repo
runCommand(["git", "clone", "https://github.com/OpenLiberty/application-stack-intro.git"])
os.chdir("application-stack-intro")

# Create new project
runCommand(["odo", "create", "my-ol-component"])

# Create odo project URL using ingress
runCommand(["odo", "url", "create", "--host", url.strip(), "--ingress"])
runCommand(["odo", "push"])

# Find the URL for the application
output = runCommand(["odo", "url", "list"])

# Test Health endpoint
testHealth(output)
processResults = subprocess.run(["odo","log"],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

#### TODO -- do we need to check tests?  maybe just once?
# look through the odo log and check the integration results.
if checkTestResults(processResults.stdout.splitlines()) > 0:
    returncode = 12
deleteProject()

sys.exit(0)
