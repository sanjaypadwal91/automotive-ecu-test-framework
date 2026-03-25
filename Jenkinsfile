pipeline {
    agent any

    tools {
        maven "Maven"

}
    environment {
        MY_VERSION = "1.0.1"
        USER = "Sanjay"
        PASS = "PASS"


    }

    stages {
        stage('📦 Build') {
            steps {
                echo "Building version ${MY_VERSION}"
                sh "mvn clean install"
                sh "pip install python"
            }
        }

        stage('🔧 Test') {
            steps { echo '🔧 Test'

            }
        }

        stage('Deploy') {
            steps {echo  'Deploy'
            withCredentials([usernamePassword(credentialsId: 'server_credemtioals', usernameVariable: 'USER', passwordVariable: 'PASS')])
            {
            sh "some script ${USER} ${PASS}"

}

            }

        }

    }
}
