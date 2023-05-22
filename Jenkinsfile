pipeline {
    agent any
    environment {
        dockerTag=getDockerTag();
        registry ="taibt2docker/nodejs-app:${dockerTag}"
        OlD_CONTAINER = "dd";
        HOST = "54.197.3.92"
	}

    stages {
        stage ("test agent") {
            agent { label 'terraform-agent' }
            environment {
                AWS_ACCESS_KEY_ID     = credentials('Access-key-ID')
                AWS_SECRET_ACCESS_KEY = credentials('Secret-access-key')
            }
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/TaiBT2/app-nodejs.git']])
                sh ' terraform -chdir=./devops-tool/infra init'
                sh ' terraform -chdir=./devops-tool/infra apply -auto-approve'
                sh " aws ec2 describe-instances \
                    --query 'Reservations[*].Instances[*].PublicIpAddress' \
                    --filters 'Name=tag:project','Values=Server-1' \
                    --output text >> devops-tool/ansible/inventory.txt"
                sh 'cat devops-tool/ansible/inventory.txt'
            }
        }
        stage ("build image and deploy server") {
            agent any
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
                                        script : "ssh -o StrictHostKeyChecking=no ubuntu@${HOST}  docker ps -q",
                                        returnStdout: true
                                    )
                                    sh "echo ${OlD_CONTAINER}"
                                    try {
                                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOST} docker rm -f ${OlD_CONTAINER}"
                                    } catch (Exception e) {
                                        echo 'Exception occurred: ' + e.toString()
                                    } finally {
                                        sh "ssh -o StrictHostKeyChecking=no ubuntu@${HOST} docker run -d -p 4000:4000 ${registry}"
                                    }
                                }
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
