pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.1"
        USER = "Sanjay"
        PASS = "PASS"


    }

    stages {
        stage('📦 Build') {
            steps {
                echo "Building version ${MY_VERSION}"
                bat "mvn clean install"
                bat  "pip install python"
            }
        }

        stage('🔧 Test') {
            steps { echo '🔧 Test'

            }
        }

        stage('Deploy') {
            steps {
            echo  'Deploy'

            echo "some script ${USER} ${PASS}"

            }

        }

    }
}
