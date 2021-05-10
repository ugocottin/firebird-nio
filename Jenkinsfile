pipeline {
	agent {
		docker {
			image 'swift:latest'
			args '-u root:sudo'
		}
	}
	stages {
		stage('Setup') {
			steps {
				sh 'rm -rf ./*'
				scm checkout
				sh 'apt-get update'
				sh 'apt-get install -y firebird-dev'
				sh 'swift package resolve'
			}
		}
		stage('Build') {
			steps {
				sh 'swift build'
			}
		}
		stage('Test') {
			steps {
				sh 'swift test'
			}
		}
	}
}