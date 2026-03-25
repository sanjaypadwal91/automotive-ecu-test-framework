@Library('your-shared-library') _   // this must match the library name

pipeline {
    agent any

    stages {
        stage('📦 Build') {
            steps {
                script {
                    buildPipeline.buildApp("1.0.1")
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