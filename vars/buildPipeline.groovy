def buildApp(version) {
    echo "Building version ${version}"
      // Maven command, not pip
}

def runPythonTests() {
    echo "Running Python tests"
    bat "pip install -r requirements.txt"   // Install Python dependencies
    bat "python test_scripts.py"             // Run Python tests
}

def runMavenTests() {
    echo "Running Maven tests"
    bat "mvn test"
}

def deployApp() {
    echo "Deploying application"
    bat "echo Deploy step simulated"
}