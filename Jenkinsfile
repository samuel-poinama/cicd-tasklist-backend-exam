pipeline {
    agent any

    options {
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timestamps()
    }

    triggers {
        pollSCM('H/2 * * * *')
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('samuel-poinama-dockerhub-password')
        SONAR_TOKEN           = credentials('samuel-poinama-sonar-token')

        DOCKERHUB_USER  = 'samuelpoinama'
        IMAGE_NAME      = "${DOCKERHUB_USER}/tasklist-backend-exam"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        FULL_IMAGE      = "${IMAGE_NAME}:${IMAGE_TAG}"

        TRIVY_REPORT    = "trivy.json"
    }

    stages {

        stage('1. Install dependencies') {
            steps {
                sh 'npm install'
            }
        }

        stage('2. Generate Prisma client') {
            steps {
                sh 'npx prisma generate'
            }
        }

        stage('3. Unit tests') {
            steps {
                sh 'npm run test:coverage'
            }
        }

        stage('4. End-to-end tests') {
            steps {
                sh 'npm run test:e2e:coverage'
            }
        }

        stage('5. SonarQube analysis') {
            steps {
                withSonarQubeEnv('sonarqube-server-1') {
                    sh """
                        npx sonar-scanner \
                          -Dsonar.token=${SONAR_TOKEN}
                    """
                }
            }
        }

        stage('6. Build Docker image') {
            steps {
                sh "docker build -t ${FULL_IMAGE} ."
            }
        }

        stage('7. Trivy security scan') {
            steps {
                sh """
                    trivy image \
                      --format json \
                      --severity HIGH,CRITICAL \
                      --report all ${FULL_IMAGE} > ${TRIVY_REPORT}

                """
            }
        }

        stage('8. Generate SBOM') {
            steps {
                sh """
                    trivy image --format spdx-json --output ${SBOM_REPORT} ${FULL_IMAGE}
                """
            }
        }

        stage('9. Archive security reports') {
            steps {
                archiveArtifacts artifacts: "${SBOM_REPORT}", allowEmptyArchive: true
            }
        }

        stage('12. Publish Docker image') {
            steps {
                sh """
                    docker login -u ${DOCKERHUB_USER} -p ${DOCKERHUB_CREDENTIALS}
                    docker push ${FULL_IMAGE}
                    docker logout
                """
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            sh "docker rmi ${FULL_IMAGE} || true"
            cleanWs()
        }
        failure {
            echo "Pipeline failed at build #${env.BUILD_NUMBER}"
        }
        success {
            echo "Pipeline succeeded: ${FULL_IMAGE} published"
        }
    }
}