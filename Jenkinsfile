pipeline {
    agent any
    environment {
        dockerTag=getDockerTag();
        registry ="taibt2docker/nodejs-app:${dockerTag}"
        OlD_CONTAINER = "dd";
        HOST = "54.197.3.92"
        PROJECT= "server_${dockerTag}"  
	}

    stages {
        stage ("build infra") {
            agent { label 'agent'}
            environment {
                AWS_ACCESS_KEY_ID     = credentials('Access-key-ID')
                AWS_SECRET_ACCESS_KEY = credentials('Secret-access-key')
                ANSIBLE_PRIVATE_KEY   = credentials('ssh-server-admin')
            }
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[url: 'https://github.com/TaiBT2/app-nodejs.git']])
                script {
                    try {
                        sh 'aws ec2 terminate-instances  --instance-ids $(aws ec2 describe-instances --query "Reservations[].Instances[].InstanceId" --filters "Name=tag:project,Values=*" --output text)'
                    }  catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                    }
                }
                
                sh ' terraform -chdir=./devops-tool/infra init'
                sh ' terraform -chdir=./devops-tool/infra apply -auto-approve -var "name_project=${PROJECT}"'
                sh ' sleep 10'
                sh ' aws ec2 describe-instances \
                    --query "Reservations[*].Instances[*].PublicIpAddress" \
                    --filters "Name=tag:project","Values=${PROJECT}" \
                    --output text >> devops-tool/ansible/inventory.txt'
                script {
                    try {
                        def ip =sh (
                        script: "cat devops-tool/ansible/inventory.txt",
                        returnStdout: true)
                        HOST = ip
                    } catch (Exception e) {
                        echo 'Exception occurred: ' + e.toString()
                    }
                }
                sshec2 ()
                
            }
        }
        stage ("build image and deploy server") {
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
                                        script : "ssh -o StrictHostKeyChecking=no ubuntu@${HOST} docker ps -q",
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
    tag=tag.substring(0,4)
    return tag
}

@NonCPS
def sshec2 (){
    while (true){
        try {
            sh 'ansible-playbook -i devops-tool/ansible/inventory.txt --private-key=${ANSIBLE_PRIVATE_KEY} devops-tool/ansible/configure-server.yml'  
            break;
        } catch (Exception e) {
        echo 'Exception occurred: ' + e.toString()
        }
    }
}