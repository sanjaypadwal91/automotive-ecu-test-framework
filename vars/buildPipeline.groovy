def buildApp(version) {
    echo "Building version ${version}"
    bat "mvn clean install"
}

def runTests() {
    echo "Running tests"
    bat "mvn test"
}

def deployApp() {
    echo "Deploying application"
    bat "echo Deploy step here"
}