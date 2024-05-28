#!/usr/bin/env groovy

@Library('factual-shared-libs') _

pipeline {
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: 4sweep
    image: 087473112489.dkr.ecr.us-east-1.amazonaws.com/4sweep:latest
    env:
      - name: RAILS_ENV
        value: test
    command: ['cat]
    tty: true
  - name: work5-ci
    image: 087473112489.dkr.ecr.us-west-1.amazonaws.com/work5-ci:latest
    env:
      - name: WORK5_TOKEN
        value: token
      - name: WORK5_HOST
        value: http://localhost:3000
      - name: WORK5_CLI_CONFIG
        value: scripts/work5/cli/ruby/fixtures/.work5.json
    command: ['cat']
    tty: true
"""
    }
  }
  stages {
    stage('Ingester Tests') {
      steps {
        container('work5-ingester') {
          withCredentials([
            file(credentialsId: 'artifactory-ruby-gem-bundle-config', variable: 'BUNDLE_CONFIG_FILE'),
          ]) {
              dir ('ingester') {
                  sh 'mkdir -p ~/.bundle'
                  sh 'cp \$BUNDLE_CONFIG_FILE ~/.bundle/config'
                  sh 'bash -c bundle install && rake test'
              }
          }
        }
      }
    }
    stage('Unit Tests') {
      steps {
        container('work5-ci') {
          withCredentials([
            file(credentialsId: 'artifactory-ruby-gem-bundle-config', variable: 'BUNDLE_CONFIG_FILE'),
            usernamePassword(credentialsId: 'artifactory-npm', usernameVariable: 'NPM_USERNAME', passwordVariable: 'NPM_PASSWORD')
          ]) {
            sh """
              export npm_config_email=\$NPM_USERNAME
              export npm_config__auth=\$(echo -n \$NPM_USERNAME:\$NPM_PASSWORD | base64 | tr -d '\\n')
              mkdir -p ~/.bundle
              cp \$BUNDLE_CONFIG_FILE ~/.bundle/config
              bash -c ./scripts/run_tests.sh
              yarn add --dev jest@27.5.1
              yarn test
            """
          }
        }
      }
    }
    stage('Deployment') {
      when {
        anyOf {
          branch 'master'
        }
      }
      environment {
        DB_HOST='work5-work5auroraclusterbc24eb9d-7jty95s9c2d8.cluster-cysdhz4wkujf.us-west-1.rds.amazonaws.com'
        DB_PORT=5432
        WORK5_DB_PASS=credentials('work5-db')
        SECRET_KEY_BASE='unusedRandomString'
        RAILS_ENV='production'
      }
      steps {
        withCredentials([usernamePassword(credentialsId: 'artifactory-npm', usernameVariable: 'ARTIFACTORY_USERNAME', passwordVariable: 'ARTIFACTORY_PASSWORD')]) {
          docker_build(
            name: 'work5-ingester',
            dockerfile_name: 'ingester/Dockerfile',
            tag: 'prod',
            flags: [
              '--build-arg BUNDLE_FOURSQUAREDEV__JFROG__IO=${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}',
              '--build-arg npm_config_email=${ARTIFACTORY_USERNAME}',
              '--build-arg npm_config__auth=$(echo -n "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" | base64 | tr -d "\\n")',
              '--build-arg npm_config_registry=https://foursquaredev.jfrog.io/artifactory/api/npm/npm/',
              '--build-arg npm_config_always_auth=true'
            ]
          )
          docker_build(
            name: 'work5',
            flags: [
              '--build-arg BUNDLE_FOURSQUAREDEV__JFROG__IO=${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}',
              '--build-arg npm_config_email=${ARTIFACTORY_USERNAME}',
              '--build-arg npm_config__auth=$(echo -n "${ARTIFACTORY_USERNAME}:${ARTIFACTORY_PASSWORD}" | base64 | tr -d "\\n")',
              '--build-arg npm_config_registry=https://foursquaredev.jfrog.io/artifactory/api/npm/npm/',
              '--build-arg npm_config_always_auth=true'
            ]
          )
          container('work5-ci') {
            withCredentials([
              file(credentialsId: 'artifactory-ruby-gem-bundle-config', variable: 'BUNDLE_CONFIG_FILE'),
            ]) {
              sh 'mkdir -p ~/.bundle'
              sh 'cp \$BUNDLE_CONFIG_FILE ~/.bundle/config'
              sh 'bash -c bundle install'
              sh 'bash -c DB_PASS=${WORK5_DB_PASS} rake db:migrate up'
            }
          }
        }
        k8s_deploy(
          cluster: 'eks-we-usw1-infra',
          team: 'places',
          app: 'work5-sidekiq',
          image_name: '087473112489.dkr.ecr.us-west-1.amazonaws.com/work5'
        )
        k8s_deploy(
          cluster: 'eks-we-usw1-infra',
          team: 'places',
          app: 'work5-rails',
          image_name: '087473112489.dkr.ecr.us-west-1.amazonaws.com/work5'
        )
      }
      post {
        success {
          slackSend(
            botUser: true,
            channel: "#work5",
            teamDomain: 'foursquare',
            baseUrl: 'https://foursquare.slack.com/services/hooks/jenkins-ci',
            color: 'good',
            tokenCredentialId: 'foursquare-work5-slack-token',
            message: "*${currentBuild.result}*: Job '${env.JOB_NAME}' build ${env.BUILD_NUMBER}\n More info at: (${env.BUILD_URL})"
          )
        }
        failure {
          slackSend(
            botUser: true,
            channel: "#work5",
            teamDomain: 'foursquare',
            baseUrl: 'https://foursquare.slack.com/services/hooks/jenkins-ci',
            color: 'danger',
            tokenCredentialId: 'foursquare-work5-slack-token',
            message: "*${currentBuild.result}*: Job '${env.JOB_NAME}' build ${env.BUILD_NUMBER}\n More info at: (${env.BUILD_URL})"
          )
        }
      }
    }
  }
}
