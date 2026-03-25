pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.2"
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
                        script {
                            buildPipeline.runPythonTests()
                        }
                    }
                }
                stage('Maven Tests') {
                    steps {
                        script {
                            buildPipeline.runMavenTests()
                        }
                    }
                }
            }
        }

        stage('🚀 Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    buildPipeline.deployApp()
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline Success"
        }
        failure {
            echo "❌ Pipeline Failed"
        }
    }
}