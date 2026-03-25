pipeline {
    agent any
    
    environment {
        MY_VERSION = "1.0.1"

    }

    stages {
        stage('📦 Build') {
            steps {
                echo "Building version ${MY_VERSION}"
            }
        }

        stage('🔧 Test') {
            steps { echo '🔧 Test'

            }
        }

        stage('Deploy') {
            steps {echo  'Deploy'

            }

        }

    }
}
