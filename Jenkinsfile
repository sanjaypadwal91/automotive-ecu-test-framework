pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.1"
    }

    stages {
        stage('📦 Build (Maven)') {
            steps {
                echo "Building version ${MY_VERSION}"
                bat "mvn clean install"
            }
        }

        stage('🐍 Setup Python') {
            steps {
                bat "python --version"
                bat "pip install -r requirements.txt"
            }
        }

        stage('🔧 Run Tests') {
            steps {
                bat "python test_script.py"
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Success"
        }
        failure {
            echo "❌ Pipeline Failed"
        }
    }
}