pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh 'cd SampleWebApp mvn test'
            }
        }
        stage('Build & Complie') {
            steps {
                sh 'cd SampleWebApp && mvn clean package'
            }
        }
        
        stage('Deploy to Tomcat Web Server') {
            steps {
                deploy adapters: [tomcat9(credentialsId: 'my_new_cicd', path: '', url: 'http://23.22.213.181:8080/')], contextPath: 'webapp', war: '**/*.war'
            }
        }
    }
}
