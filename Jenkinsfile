pipeline {
    agent any

    environment {
        MY_VERSION = "1.0.1"
    }

    stages {
        stage('📦 Build') {
            steps {
                script {
                    // Test if buildPipeline.groovy is visible
                    echo "Testing if buildPipeline exists: ${buildPipeline != null}"

                    // Only call buildPipeline function if it exists
                    if (buildPipeline != null) {
                        buildPipeline.buildApp(MY_VERSION)
                    } else {
                        error("buildPipeline.groovy not found!")
                    }
                }
            }
        }

        stage('🧪 Tests (Parallel)') {
            parallel {
                stage('Python Tests') {
                    steps {
                        script {
                            if (buildPipeline != null) {
                                buildPipeline.runPythonTests()
                            }
                        }
                    }
                }
                stage('Maven Tests') {
                    steps {
                        script {
                            if (buildPipeline != null) {
                                buildPipeline.runMavenTests()
                            }
                        }
                    }
                }
            }
        }

        stage('🚀 Deploy') {
            steps {
                script {
                    if (buildPipeline != null) {
                        buildPipeline.deployApp()
                    }
                }
            }
        }
    }
}