@Library('my-shared-lib') _   // optional if using global lib

pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.1"
    }

    stages {
        stage('📦 Build') {
            steps {
                script {
                    buildPipeline.buildApp(MY_VERSION)
                }
            }
        }

        stage('🔧 Test') {
            steps {
                script {
                    buildPipeline.runTests()
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    buildPipeline.deployApp()
                }
            }
        }
    }
}