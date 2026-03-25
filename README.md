# 📌 Project Overview
Enterprise-grade testing framework for automotive Electronic Control Units (ECUs) with CI/CD integration.

## 🎯 Key Features
- **Multi-layer Testing**: Unit, Integration, HIL, Performance
- **Automated CI/CD**: Jenkins pipeline with parallel execution
- **Hardware Integration**: Support for HIL rigs and real ECUs
- **Comprehensive Reporting**: HTML, JUnit, Allure reports
- **ISO 26262 Compliance**: Safety-critical testing standards

## 🏗️ Architecture

─────────────────────────────────────────────┐
│ Jenkins CI/CD Pipeline │
├─────────────────────────────────────────────┤
│ Robot Framework │ Pytest │ HIL Tests │
├─────────────────────────────────────────────┤
│ ECU Simulator / HIL Rigs │
└─────────────────────────────────────────────┘## Auto-build test Fri Mar 20 15:58:26 WEST 2026

CODE_CHANGES = getGitChanges()
pipeline {
    agent any
    
    environment {MY_VAR = "Learning"

    }

    stages {
        when {
            expression {BRANCH_NAME == "dev"  &&  CODE_CHANGES == true}
         }
        stage('📦 Build') {
            steps {echo  "Buinding"

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
            withCredentials([usernamePassword(credentialsId: 'server_credemtioals', usernameVariable: 'USER', passwordVariable: 'PASS')])
            {
            sh "some script ${USER} ${PASS}"

}

            }

        }

    }
}





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
                bat "python  -m pip install --upgrade pip"
                bat "pip install python"
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
