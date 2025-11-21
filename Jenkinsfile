@Library('jenkins-shared-lib') _

pipeline {
    agent { label "worker" }

    tools {
        maven 'M3'
    }

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${PATH}"

        SONAR_PROJECT_KEY = 'com.mycompany.app:my-maven-project'
        SONAR_TOKEN = credentials('sonar-token')

        DOCKERHUB_CREDENTIALS = credentials('dockerCred')  
        DOCKER_IMAGE = 'aslahea/my-maven-app'                          
    }

    stages {
        stage('Checkout Code') {
            steps {
                echo '🔹 Checking out code from GitHub...'
                checkout scmGit(
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[url: 'https://github.com/aslahea/sample-maven-app.git']]
                )
            }
        }

        stage('Build') {
            steps {
                echo '🔹 Building the Maven project...'
                sh '''
                    echo "----- BUILD LOG -----" > build_report.txt
                    mvn clean package -DskipTests >> build_report.txt 2>&1
                '''
            }
        }

        stage('Unit Test') {
            steps {
                echo '🔹 Running Unit Tests...'
                sh '''
                    echo "----- TEST LOG -----" > test_report.txt
                    mvn test >> test_report.txt 2>&1
                '''
                junit '**/target/surefire-reports/*.xml'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                echo '🔹 Starting SonarQube Analysis...'
                withSonarQubeEnv('sonar') {
                    sh '''
                        echo "----- SONAR ANALYSIS LOG -----" > sonar_report.txt
                        mvn sonar:sonar \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.token=${SONAR_TOKEN} \
                            -Dsonar.projectName='my-maven-project' >> sonar_report.txt 2>&1
                    '''
                }
            }
        }

        stage('Quality Gate Check') {
            options {
                timeout(time: 20, unit: 'MINUTES')
            }
            steps {
                echo 'Checking SonarQube Quality Gate...'
                script {
                    def qg = waitForQualityGate()
                    if (qg.status != 'OK') {
                        error "❌ Quality Gate failed: ${qg.status}"
                    } else {
                        echo "Quality Gate Passed Successfully!"
                    }
                }
            }
        }

        stage('Docker Login') {
	    steps {
		echo '🔹 Logging into DockerHub...'
		withCredentials([usernamePassword(credentialsId: 'dockerCred', usernameVariable: 'dockerUser', passwordVariable: 'dockerPass')]) {
		    sh '''
		        echo "${dockerPass}" | docker login -u "${dockerUser}" --password-stdin
		    '''
		}
	    }
	}


        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Docker Tag') {
            steps {
                echo 'Tagging Docker image with "latest"...'
                sh '''
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:latest
                '''
            }
        }

        stage('Docker Push') {
            steps {
                echo '🔹 Pushing Docker image to DockerHub...'
                sh '''
                    docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    docker push ${DOCKER_IMAGE}:latest
                '''
            }
        }
        
        stage('Docker Info') {
            steps {
                echo '📝 Generating Docker Report...'
                sh '''
                    echo "----- DOCKER IMAGE INFO -----" > docker_report.txt
                    echo "Docker Image: ${DOCKER_IMAGE}" >> docker_report.txt
                    echo "Build Number: ${BUILD_NUMBER}" >> docker_report.txt
                    echo "" >> docker_report.txt
                    echo "--- Details of pushed image (by build number) ---" >> docker_report.txt
                    docker inspect ${DOCKER_IMAGE}:${BUILD_NUMBER} >> docker_report.txt 2>&1 || true
                    echo "" >> docker_report.txt
                    echo "--- Details of pushed image (latest tag) ---" >> docker_report.txt
                    docker inspect ${DOCKER_IMAGE}:latest >> docker_report.txt 2>&1 || true
                    echo "" >> docker_report.txt
                    echo "--- Recently Pushed Images ---" >> docker_report.txt
                    docker images | grep ${DOCKER_IMAGE} >> docker_report.txt 2>&1 || true
                '''
            }
        }

        stage('Docker Cleanup') {
	    steps {
		echo '🧹 Cleaning up local Docker containers and images...'
		sh '''
		    # Stop all running containers (ignore errors if none)
		    docker ps -q | xargs -r docker stop || true

		    # Remove all stopped containers
		    docker container prune -f

		    # Remove dangling (untagged) images
		    docker image prune -f

		    # Optionally remove your specific build image
		    docker rmi ${DOCKER_IMAGE}:${BUILD_NUMBER} || true
		    docker rmi ${DOCKER_IMAGE}:latest || true
		'''
	    }
	}

        stage('Docker Logout') {
            steps {
                echo '🔹 Logging out from DockerHub...'
                sh 'docker logout'
            }
        }
    }

    post {
        always {
            echo '📦 Archiving build reports...'
            // Ensure docker_report.txt is also archived
            archiveArtifacts artifacts: '*.txt', fingerprint: true 
        }

        success {
            echo '✅ Build succeeded - triggering email notification'
            sendEmailNotification(
                currentBuild.currentResult,
                [
                    "Build Report": "build_report.txt",
                    "Unit Test Report": "test_report.txt",
                    "Sonar Analysis Report": "sonar_report.txt",
                    "Docker Report": "docker_report.txt"
                ]
            )
        }

        failure {
            echo '❌ Build failed - triggering email notification'
            sendEmailNotification(
                currentBuild.currentResult,
                [
                    "Build Report": "build_report.txt",
                    "Unit Test Report": "test_report.txt",
                    "Sonar Analysis Report": "sonar_report.txt",
                    "Docker Report": "docker_report.txt"
                ]
            )
        }

        aborted {
            echo '⚠️ Build aborted - triggering email notification'
            sendEmailNotification(
                currentBuild.currentResult,
                [
                    "Build Report": "build_report.txt",
                    "Unit Test Report": "test_report.txt",
                    "Sonar Analysis Report": "sonar_report.txt",
                    "Docker Report": "docker_report.txt"
                ]
            )
        }
    }
}
