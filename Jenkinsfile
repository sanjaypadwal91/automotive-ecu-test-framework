
CODE_CHANGES = getGitChanges()
pipeline {
    agent any
    
    environment {MY_VESRION = "1.0.1"

    }

    stages {

        stage('📦 Build') {
            steps {echo  "Buinding version $(MY_VERSION)"

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
