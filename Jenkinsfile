pipeline {
    agent any
    environment {
        TF_IN_AUTOMATION = "true"
        TF_CLI_CONFIG_FILE = credentials('badf87b5-c81c-440d-87b5-1698b311dcdd')
    }

    stages {
        stage('init') {
            steps {
                sh 'ls'
                sh 'terraform init -no-color'
            }
        }
        stage('Plan') {
            steps {
                sh 'terraform plan -no-color'
            }
        }
    }
}
