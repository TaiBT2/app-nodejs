pipeline {
    agent any
    environment {
        dockerTag=getDockerTag();
        registry ="taibt2docker/nodejs-app:${dockerTag}"
        OlD_CONTAINER = "d";
	}

    stages {

        stage ('build image') {
            steps {
                sh "docker build . -t ${registry}"
            }
        }

        stage ('upload image') {
            steps {
                withDockerRegistry(credentialsId: 'docker-hub', url: 'https://index.docker.io/v1/') {
                    sh "docker push ${registry}"
                }
            }
        }
        stage ('ssh-server') {
            steps {
                sshagent(['ssh-server-admin']) {
                        script {
                            OlD_CONTAINER =sh (
                                script : "ssh -o StrictHostKeyChecking=no ubuntu@34.230.21.186  docker ps -q",
                                returnStdout: true
                            )
                            sh "echo ${OlD_CONTAINER}"
                            try {
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@34.230.21.186 docker rm -f ${OlD_CONTAINER}"
                            } catch (Exception e) {
                                echo 'Exception occurred: ' + e.toString()
                            } finally {
                                sh "ssh -o StrictHostKeyChecking=no ubuntu@34.230.21.186 docker run -d -p 4000:4000 ${registry}"
                            }
                        }
                        
                }
            }
        }
    }
}

def getDockerTag(){
    def tag  = sh script: 'git rev-parse HEAD', returnStdout: true
    return tag
}
