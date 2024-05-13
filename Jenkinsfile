pipeline {
    agent any

    stages {
        stage('Test') {
            steps {
                sh 'cd SampleWebApp mvn test'
            }
        }
        stage('Build & Compile') {
            steps {
                sh 'cd SampleWebApp && mvn clean package'
            }
        }
        
        stage('Deploy to Tomcat Web Server') {
            steps {
                deploy adapters: [tomcat9(credentialsId: 'Deploy_tomcart', path: '', url: 'http://3.93.186.165:8080/')], contextPath: 'web_app', war: '**/*.war'
            }
        }
    }
}
