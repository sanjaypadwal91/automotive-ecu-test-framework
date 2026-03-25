pipeline {
    agent any
    
    environment {
        BUILD_NUM = "${env.BUILD_NUMBER}"
        REPORT_DIR = "${env.WORKSPACE}\\reports"
    }

    stages {
        stage('📦 Checkout') {
            steps {
                echo 'Checking out from GitHub...'
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        url: 'https://github.com/sanjaypadwal91/automotive-ecu-test-framework.git'
                    ]]
                ])
                echo '✅ Code checked out!'
            }
        }

        stage('🔧 Setup') {
            steps {
                echo 'Setting up environment...'
                bat 'python --version'
                bat 'pip install robotframework pytest pytest-html --quiet'
                echo '✅ Environment ready'
            }
        }

        stage('🤖 Robot Tests') {
            steps {
                echo 'Running Robot Framework tests...'
                bat """
                    if not exist ${REPORT_DIR}\\robot mkdir ${REPORT_DIR}\\robot
                    cd robot_framework
                    robot --outputdir ${REPORT_DIR}\\robot --include smoke testsuites\\
                """
            }
            post {
                always {
                    step([
                        $class: 'RobotPublisher',
                        outputPath: "${REPORT_DIR}\\robot",
                        outputFileName: "output.xml",
                        reportFileName: "report.html",
                        logFileName: "log.html"
                    ])
                }
            }
        }

        stage('🐍 Pytest Tests') {
            steps {
                echo 'Running Pytest tests...'
                bat """
                    if not exist ${REPORT_DIR}\\pytest mkdir ${REPORT_DIR}\\pytest
                    cd pytest_tests
                    pytest -v --html=${REPORT_DIR}\\pytest\\report.html --self-contained-html test_brake\\ test_can\\
                """
            }
            post {
                always {
                    junit testResults: "${REPORT_DIR}/pytest/junit.xml", allowEmptyResults: true
                    publishHTML([
                        reportDir: "${REPORT_DIR}\\pytest",
                        reportFiles: 'report.html',
                        reportName: 'Pytest Report'
                    ])
                }
            }
        }

        stage('📊 Report') {
            steps {
                echo 'Generating final report...'
                bat """
                    echo ======================================== > ${REPORT_DIR}\\FINAL_REPORT.txt
                    echo BUILD SUCCESSFUL! >> ${REPORT_DIR}\\FINAL_REPORT.txt
                    echo Build: ${env.BUILD_NUMBER} >> ${REPORT_DIR}\\FINAL_REPORT.txt
                    echo Date: %DATE% %TIME% >> ${REPORT_DIR}\\FINAL_REPORT.txt
                    echo ======================================== >> ${REPORT_DIR}\\FINAL_REPORT.txt
                """
            }
            post {
                always {
                    archiveArtifacts artifacts: 'reports/**/*'
                }
            }
        }
    }

    post {
        success {
            echo '✅ BUILD SUCCESSFUL!'
        }
        failure {
            echo '❌ BUILD FAILED!'
        }
    }
}
