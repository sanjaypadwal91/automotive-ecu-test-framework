#!/usr/bin/env groovy
/**
 * Jenkins Pipeline for Automotive ECU Test Framework
 *
 * This pipeline follows company standards for CI/CD:
 * - Multi-stage pipeline with parallel execution
 * - Quality gates for code coverage
 * - Automated reporting and notifications
 * - Support for HIL hardware testing
 *
 * @author DevOps Team
 * @version 2.0.0
 */

// Pipeline configuration
properties([
    // Keep only last 10 builds
    buildDiscarder(logRotator(numToKeepStr: '10')),

    // Allow manual triggers with parameters
    parameters([
        choice(
            name: 'TEST_LEVEL',
            choices: ['smoke', 'regression', 'full', 'certification'],
            description: 'Level of testing to execute'
        ),
        string(
            name: 'TARGET_ECU',
            defaultValue: 'brake_controller',
            description: 'Target ECU for testing'
        ),
        choice(
            name: 'ENVIRONMENT',
            choices: ['virtual', 'hil_staging', 'hil_production'],
            description: 'Test environment'
        ),
        booleanParam(
            name: 'DEPLOY_ARTIFACTS',
            defaultValue: false,
            description: 'Deploy artifacts to Artifactory'
        )
    ]),

    // Disable concurrent builds for HIL tests
    disableConcurrentBuilds(abortPrevious: false),

    // Timeout after 2 hours
    timeout(time: 2, unit: 'HOURS')
])

// Pipeline definition
pipeline {
    agent any

    environment {
        // Build information
        BUILD_ID = "${env.BUILD_NUMBER}"
        COMMIT_HASH = "${env.GIT_COMMIT.take(8)}"
        BUILD_VERSION = "${env.BUILD_ID}-${COMMIT_HASH}"

        // Paths
        WORKSPACE_DIR = "${env.WORKSPACE}"
        TEST_REPORT_DIR = "${WORKSPACE_DIR}/reports"

        // Test environment
        PYTHONPATH = "${WORKSPACE_DIR}"
        ROBOT_OPTIONS = "--outputdir ${TEST_REPORT_DIR}/robot --loglevel TRACE"
        PYTEST_OPTIONS = "--junitxml=${TEST_REPORT_DIR}/pytest/junit.xml --html=${TEST_REPORT_DIR}/pytest/report.html"

        // Quality gates
        MIN_UNIT_TEST_COVERAGE = "80"
        MAX_HIL_TEST_FAILURES = "0"
    }

    stages {
        // Stage 1: Code Checkout & Validation
        stage('📦 Checkout & Validate') {
            steps {
                script {
                    // Checkout with submodules
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        extensions: [
                            [$class: 'SubmoduleOption', recursiveSubmodules: true],
                            [$class: 'CleanBeforeCheckout'],
                            [$class: 'LocalBranch', localBranch: '**']
                        ],
                        userRemoteConfigs: [[
                            url: 'https://github.com/YOUR_USERNAME/automotive-ecu-test-framework.git',
                            credentialsId: 'github-token'
                        ]]
                    ])

                    // Print build information
                    echo """
                    ========================================
                    🚀 Build Information
                    ========================================
                    Build Number: ${env.BUILD_NUMBER}
                    Commit Hash: ${COMMIT_HASH}
                    Test Level: ${params.TEST_LEVEL}
                    Target ECU: ${params.TARGET_ECU}
                    Environment: ${params.ENVIRONMENT}
                    ========================================
                    """
                }
            }
        }

        // Stage 2: Environment Setup
        stage('🔧 Setup Environment') {
            parallel {
                stage('Install Dependencies') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    python3 -m pip install --upgrade pip
                                    pip install -r requirements.txt
                                    pip install pytest-xdist robotframework-pabot
                                '''
                            } else {
                                bat '''
                                    python -m pip install --upgrade pip
                                    pip install -r requirements.txt
                                    pip install pytest-xdist robotframework-pabot
                                '''
                            }
                        }
                    }
                }

                stage('Create Directories') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    mkdir -p ${TEST_REPORT_DIR}/{robot,pytest,coverage,allure}
                                    mkdir -p ${WORKSPACE_DIR}/logs
                                '''
                            } else {
                                bat '''
                                    mkdir %TEST_REPORT_DIR%\\robot
                                    mkdir %TEST_REPORT_DIR%\\pytest
                                    mkdir %TEST_REPORT_DIR%\\coverage
                                    mkdir %WORKSPACE_DIR%\\logs
                                '''
                            }
                        }
                    }
                }

                stage('Verify Tools') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    python --version
                                    robot --version
                                    pytest --version
                                    git --version
                                '''
                            } else {
                                bat '''
                                    python --version
                                    robot --version
                                    pytest --version
                                    git --version
                                '''
                            }
                        }
                    }
                }
            }
        }

        // Stage 3: Static Analysis & Code Quality
        stage('🔍 Static Analysis') {
            parallel {
                stage('Code Linting') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    # Python linting
                                    pip install pylint flake8 black
                                    flake8 --max-line-length=120 --statistics pytest_tests/
                                    pylint --fail-under=8.0 pytest_tests/
                                '''
                            } else {
                                bat '''
                                    pip install pylint flake8 black
                                    flake8 --max-line-length=120 --statistics pytest_tests/
                                    pylint --fail-under=8.0 pytest_tests/
                                '''
                            }
                        }
                    }
                }

                stage('Security Scan') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh '''
                                    # Install security tools
                                    pip install bandit safety

                                    # Run security scan
                                    bandit -r pytest_tests/ -f json -o ${TEST_REPORT_DIR}/bandit.json
                                    safety check -r requirements.txt --json > ${TEST_REPORT_DIR}/safety.json
                                '''
                            } else {
                                bat '''
                                    pip install bandit safety
                                    bandit -r pytest_tests/ -f json -o %TEST_REPORT_DIR%\\bandit.json
                                    safety check -r requirements.txt --json > %TEST_REPORT_DIR%\\safety.json
                                '''
                            }
                        }
                    }
                }
            }
        }

        // Stage 4: Build
        stage('🏗️ Build') {
            steps {
                script {
                    if (isUnix()) {
                        sh '''
                            echo "Building ECU firmware..."
                            # Simulate build process
                            mkdir -p build/
                            echo "BUILD_VERSION=${BUILD_VERSION}" > build/manifest.txt
                            echo "BUILD_TIMESTAMP=$(date)" >> build/manifest.txt
                        '''
                    } else {
                        bat '''
                            echo Building ECU firmware...
                            mkdir build
                            echo BUILD_VERSION=%BUILD_VERSION% > build\\manifest.txt
                            echo BUILD_TIMESTAMP=%DATE% %TIME% >> build\\manifest.txt
                        '''
                    }
                }
            }

            post {
                success {
                    archiveArtifacts artifacts: 'build/**/*', fingerprint: true
                }
            }
        }

        // Stage 5: Unit Tests (Parallel)
        stage('🧪 Unit Tests') {
            parallel {
                stage('Robot Unit Tests') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh """
                                    cd robot_framework
                                    robot --include unit \
                                          --outputdir ${TEST_REPORT_DIR}/robot/unit \
                                          --name "Robot Unit Tests" \
                                          testsuites/
                                """
                            } else {
                                bat """
                                    cd robot_framework
                                    robot --include unit ^
                                          --outputdir %TEST_REPORT_DIR%\\robot\\unit ^
                                          --name "Robot Unit Tests" ^
                                          testsuites\\
                                """
                            }
                        }
                    }
                    post {
                        always {
                            step([
                                $class: 'RobotPublisher',
                                outputPath: "${TEST_REPORT_DIR}/robot/unit",
                                outputFileName: "output.xml",
                                reportFileName: "report.html",
                                logFileName: "log.html"
                            ])
                        }
                    }
                }

                stage('Pytest Unit Tests') {
                    steps {
                        script {
                            if (isUnix()) {
                                sh """
                                    cd pytest_tests
                                    pytest unit/ \
                                        -m unit \
                                        -n auto \
                                        --cov=. \
                                        --cov-report=html:${TEST_REPORT_DIR}/coverage \
                                        --cov-report=xml:${TEST_REPORT_DIR}/coverage.xml \
                                        ${PYTEST_OPTIONS}
                                """
                            } else {
                                bat """
                                    cd pytest_tests
                                    pytest unit/ ^
                                        -m unit ^
                                        -n 2 ^
                                        --cov=. ^
                                        --cov-report=html:%TEST_REPORT_DIR%\\coverage ^
                                        --cov-report=xml:%TEST_REPORT_DIR%\\coverage.xml ^
                                        %PYTEST_OPTIONS%
                                """
                            }
                        }
                    }
                    post {
                        always {
                            junit testResults: "${TEST_REPORT_DIR}/pytest/junit.xml"
                            publishHTML([
                                reportDir: "${TEST_REPORT_DIR}/coverage",
                                reportFiles: 'index.html',
                                reportName: 'Code Coverage Report'
                            ])
                        }
                    }
                }
            }
        }

        // Stage 6: Integration Tests
        stage('🔗 Integration Tests') {
            when {
                expression { params.TEST_LEVEL in ['regression', 'full', 'certification'] }
            }
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            cd pytest_tests
                            pytest integration/ \
                                -m integration \
                                -n 4 \
                                --timeout=300 \
                                ${PYTEST_OPTIONS}
                        """
                    } else {
                        bat """
                            cd pytest_tests
                            pytest integration/ ^
                                -m integration ^
                                -n 2 ^
                                --timeout=300 ^
                                %PYTEST_OPTIONS%
                        """
                    }
                }
            }
        }

        // Stage 7: Hardware-in-the-Loop Tests
        stage('🔧 HIL Tests') {
            when {
                expression { params.ENVIRONMENT.startsWith('hil') && params.TEST_LEVEL in ['full', 'certification'] }
            }
            steps {
                script {
                    echo """
                    ========================================
                    🔧 Running HIL Tests
                    ========================================
                    Environment: ${params.ENVIRONMENT}
                    Target ECU: ${params.TARGET_ECU}
                    ========================================
                    """

                    if (isUnix()) {
                        sh """
                            # Reserve HIL rig
                            python3 scripts/hil_reserve.py --rig-pool=${params.ENVIRONMENT}

                            # Flash ECU
                            python3 scripts/hil_flash.py --ecu=${params.TARGET_ECU}

                            # Run HIL tests
                            cd tests/hil
                            pytest . \
                                --rig-id=${params.ENVIRONMENT} \
                                --ecu=${params.TARGET_ECU} \
                                --junitxml=${TEST_REPORT_DIR}/hil/results.xml \
                                --html=${TEST_REPORT_DIR}/hil/report.html
                        """
                    } else {
                        bat """
                            python scripts/hil_reserve.py --rig-pool=%ENVIRONMENT%
                            python scripts/hil_flash.py --ecu=%TARGET_ECU%
                            cd tests\\hil
                            pytest . ^
                                --rig-id=%ENVIRONMENT% ^
                                --ecu=%TARGET_ECU% ^
                                --junitxml=%TEST_REPORT_DIR%\\hil\\results.xml ^
                                --html=%TEST_REPORT_DIR%\\hil\\report.html
                        """
                    }
                }
            }
            post {
                always {
                    junit testResults: "${TEST_REPORT_DIR}/hil/*.xml"
                    publishHTML([
                        reportDir: "${TEST_REPORT_DIR}/hil",
                        reportFiles: 'report.html',
                        reportName: 'HIL Test Report'
                    ])
                }
            }
        }

        // Stage 8: Performance Tests
        stage('⚡ Performance Tests') {
            when {
                expression { params.TEST_LEVEL in ['full', 'certification'] }
            }
            steps {
                script {
                    if (isUnix()) {
                        sh """
                            cd tests/performance
                            pytest . \
                                --benchmark-json=${TEST_REPORT_DIR}/performance/benchmark.json \
                                --benchmark-histogram=${TEST_REPORT_DIR}/performance/histogram.html
                        """
                    } else {
                        bat """
                            cd tests\\performance
                            pytest . ^
                                --benchmark-json=%TEST_REPORT_DIR%\\performance\\benchmark.json ^
                                --benchmark-histogram=%TEST_REPORT_DIR%\\performance\\histogram.html
                        """
                    }
                }
            }
        }

        // Stage 9: Quality Gate
        stage('🎯 Quality Gate') {
            steps {
                script {
                    // Parse coverage report
                    def coverage = readFile("${TEST_REPORT_DIR}/coverage.xml")
                    def coveragePercent = extractCoverage(coverage)

                    // Check coverage threshold
                    if (coveragePercent < MIN_UNIT_TEST_COVERAGE.toInteger()) {
                        error("Code coverage ${coveragePercent}% below threshold ${MIN_UNIT_TEST_COVERAGE}%")
                    }

                    // Check test failures
                    def testResults = junit testResults: "${TEST_REPORT_DIR}/**/junit.xml"
                    if (testResults.failCount > 0) {
                        error("${testResults.failCount} test failures detected")
                    }

                    echo "✅ Quality gate passed! Coverage: ${coveragePercent}%"
                }
            }
        }

        // Stage 10: Generate Reports
        stage('📊 Generate Reports') {
            steps {
                script {
                    // Generate Allure report
                    if (isUnix()) {
                        sh """
                            allure generate ${TEST_REPORT_DIR}/allure-results \
                                -o ${TEST_REPORT_DIR}/allure-report \
                                --clean
                        """
                    } else {
                        bat """
                            allure generate %TEST_REPORT_DIR%\\allure-results ^
                                -o %TEST_REPORT_DIR%\\allure-report ^
                                --clean
                        """
                    }

                    // Generate summary report
                    def summary = """
                    ========================================
                    📊 Test Execution Summary
                    ========================================
                    Build: ${env.BUILD_NUMBER}
                    Version: ${BUILD_VERSION}
                    Date: ${new Date()}

                    Test Level: ${params.TEST_LEVEL}
                    Target ECU: ${params.TARGET_ECU}
                    Environment: ${params.ENVIRONMENT}

                    Results:
                    - Unit Tests: ${testResults?.passCount ?: 0} passed
                    - Integration: ${integrationResults?.passCount ?: 0} passed
                    - HIL Tests: ${hilResults?.passCount ?: 0} passed

                    Coverage: ${coveragePercent}%

                    ========================================
                    """

                    writeFile file: "${TEST_REPORT_DIR}/summary.txt", text: summary
                }
            }
            post {
                always {
                    publishHTML([
                        reportDir: "${TEST_REPORT_DIR}/allure-report",
                        reportFiles: 'index.html',
                        reportName: 'Allure Test Report'
                    ])
                    archiveArtifacts artifacts: "${TEST_REPORT_DIR}/**/*"
                }
            }
        }

        // Stage 11: Deploy Artifacts
        stage('📦 Deploy Artifacts') {
            when {
                expression { params.DEPLOY_ARTIFACTS && params.TEST_LEVEL == 'full' }
            }
            steps {
                script {
                    echo "Deploying artifacts to Artifactory..."
                    // Simulate deployment
                    if (isUnix()) {
                        sh """
                            echo "Deploying build artifacts..."
                            tar -czf automotive-ecu-${BUILD_VERSION}.tar.gz build/
                            # artifactory upload automotive-ecu-${BUILD_VERSION}.tar.gz
                        """
                    } else {
                        bat """
                            echo Deploying build artifacts...
                            tar -czf automotive-ecu-%BUILD_VERSION%.tar.gz build\\
                        """
                    }
                }
            }
        }
    }

    // Post-build actions
    post {
        success {
            script {
                // Send success notification
                emailext(
                    to: 'team@company.com',
                    subject: "✅ [SUCCESS] Build ${env.BUILD_NUMBER} - ${params.TARGET_ECU}",
                    body: """
                    Build successful!

                    Details:
                    - Build: ${env.BUILD_URL}
                    - Version: ${BUILD_VERSION}
                    - Tests: ${testResults?.passCount ?: 0} passed
                    - Coverage: ${coveragePercent}%

                    Reports: ${env.BUILD_URL}allure
                    """
                )

                // Update status badge
                currentBuild.description = "✅ ${BUILD_VERSION} - ${params.TEST_LEVEL}"
            }
        }

        failure {
            script {
                // Send failure notification
                emailext(
                    to: 'team@company.com',
                    subject: "❌ [FAILED] Build ${env.BUILD_NUMBER} - ${params.TARGET_ECU}",
                    body: """
                    Build failed!

                    Details:
                    - Build: ${env.BUILD_URL}
                    - Version: ${BUILD_VERSION}

                    Check console output: ${env.BUILD_URL}console
                    """
                )

                currentBuild.description = "❌ ${BUILD_VERSION} - Failed"
            }
        }

        always {
            script {
                // Clean up workspace
                cleanWs()
                echo "Pipeline completed at ${new Date()}"
            }
        }
    }
}

// Helper function to extract coverage
def extractCoverage(String coverageXml) {
    def coverage = 0
    try {
        def xml = new XmlParser().parseText(coverageXml)
        def lineRate = xml.@line-rate
        coverage = (lineRate.toFloat() * 100).toInteger()
    } catch (Exception e) {
        echo "Failed to parse coverage: ${e.message}"
        coverage = 0
    }
    return coverage
}
EOF

# Commit Jenkinsfile
git add Jenkinsfile
git commit -m "feat(ci): add professional Jenkins pipeline with quality gates

- Multi-stage pipeline with parallel execution
- Quality gates for code coverage (80% minimum)
- HIL testing integration
- Automated reporting and notifications
- Allure report generation"