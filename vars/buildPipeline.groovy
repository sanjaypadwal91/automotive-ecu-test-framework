def buildApp(version) {
    echo "Building version ${version}"
    bat "pip install clean install"
}

def runPythonTests() {
    echo "Running Python tests"
    bat "pip install -r requirements.txt"
    bat "python test_script.py"
}

def runMavenTests() {
    echo "Running Maven tests"
    bat "mvn test"
}

def deployApp() {
    echo "Deploying application"
    bat "echo Deploy step simulated"
}