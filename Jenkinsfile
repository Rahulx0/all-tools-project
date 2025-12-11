pipeline  {
    agent any
    environment {
        TF_IN_AUTOMATION = "true"
        TF_CLI_CONFIG_FILE=credentials('aws-creds')
    }

    stages{
        stage('Init'){
            steps{
                sh 'ls'
                sh 'terraform init -no-color'


            }
        }
    stages{
        stage('Plan'){
            steps{
                sh 'terraform plan -no-color'

        }
        }
    }

}
}