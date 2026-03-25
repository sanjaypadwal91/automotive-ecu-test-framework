pipeline {
    agent any

    stages {
        stage('📦 Build') {
            steps {
                script {
                    // This will work only if vars/buildPipeline.groovy exists
                    echo "Testing if buildPipeline exists: ${this.hasProperty('buildPipeline')}"
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