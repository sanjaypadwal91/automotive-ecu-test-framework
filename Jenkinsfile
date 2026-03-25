@Library('your-shared-library') _   // this must match the library name

pipeline {
    agent any

    stages {
        stage('📦 Build') {
            steps {
                script {
                    buildPipeline.buildApp("main")
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