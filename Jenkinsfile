@Library('your-shared-library') _

pipeline {
    agent any

    stages {
        stage('📦 Build') {
            steps {
                script {
                    buildPipeline.buildApp("dev")
                }
            }
        }

        stage('🧪 Tests') {
            steps {
                script {
                    buildPipeline.runPythonTests()
                    buildPipeline.runMavenTests()
                }
            }
        }

        stage('🚀 Deploy') {
            steps {
                script {
                    buildPipeline.deployApp()
                }
            }
        }
    }
}