@Library('your-shared-library') _

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

        stage('🧪 Tests (Parallel)') {
            parallel {
                stage('Python Tests') {
                    steps {
                        buildPipeline.runPythonTests()
                    }
                }
                stage('Maven Tests') {
                    steps {
                        buildPipeline.runMavenTests()
                    }
                }
            }
        }

        stage('🚀 Deploy') {
            steps {
                buildPipeline.deployApp()
            }
        }
    }
}