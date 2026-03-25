pipeline {
    agent any
    
    // Environment variables available to all stages
    environment {
        APP_NAME = 'myapp'
        BUILD_TIME = sh(script: 'date', returnStdout: true).trim()
    }
    
    stages {
        stage('Setup') {
            steps {
                script {
                    echo "Building ${APP_NAME}"
                    echo "Started at: ${BUILD_TIME}"
                    
                    // Create a build directory
                    sh 'mkdir -p build'
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    // Simulate building an app
                    echo "Compiling code..."
                    
                    // Create a simple file as if we built something
                    writeFile file: 'build/app.jar', text: 'This is a fake JAR file'
                    
                    // Check if build succeeded
                    if (fileExists('build/app.jar')) {
                        echo "✅ Build successful!"
                    } else {
                        error "❌ Build failed!"
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo "Running tests..."
                    
                    def tests = ['unit tests', 'integration tests', 'security tests']
                    
                    tests.each { test ->
                        echo "Running ${test}..."
                        // Simulate test execution
                        sleep(1)  // Wait 1 second
                    }
                    
                    echo "✅ All tests passed!"
                }
            }
        }
        
        stage('Deploy') {
            when {
                // Only run this stage on the main branch
                branch 'main'
            }
            steps {
                script {
                    // Ask for confirmation before deploying
                    def deploy = input(
                        message: "Deploy to production?",
                        ok: "Yes, deploy it!",
                        parameters: [string(defaultValue: 'prod', description: 'Environment', name: 'ENV')]
                    )
                    
                    echo "Deploying to ${deploy}..."
                    echo "Deployment complete!"
                }
            }
        }
    }
    
    // This runs after all stages
    post {
        success {
            echo "🎉 Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
    }
}
