pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.1"
    }

    stages {
        stage('📦 Build') {
            steps {
                echo "Building version ${MY_VERSION}"
                bat "echo Build running"
            }
        }

        stage('🔧 Test') {
            steps {
                bat "echo Running tests"
            }
        }

        stage('Deploy') {
            steps {
                bat "echo Deploying"
            }
        }
    }

    post {
        failure {
            echo "❌ Pipeline failed! Check the logs above."
        }
    }
}