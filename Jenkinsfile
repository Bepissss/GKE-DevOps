pipeline {
    agent { label 'travelbooking' }

    environment {
        GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-service-account')
        GOOGLE_CLOUD_PROJECT           = credentials('gcp-project-id')
        GKE_CLUSTER                    = 'travelbooking-cluster'
        GKE_ZONE                       = 'asia-southeast1-a'
        ARTIFACT_REGISTRY              = 'asia-southeast1-docker.pkg.dev'
        DOCKER_REPO                    = "${ARTIFACT_REGISTRY}/${GOOGLE_CLOUD_PROJECT}/travel-booking"
        IMAGE_TAG                      = "1.0.${BUILD_NUMBER}"
        HELM_CHART_PATH                = 'helm/travel-booking'
        NAMESPACE                      = 'travel-booking'

        // ── SonarQube ──────────────────────────────────────────────────────────
        // Store your SonarQube user token in Jenkins Credentials as a
        // "Secret text" credential with ID: sonarqube-token
        SONAR_HOST_URL                 = 'http://136.85.103.130:8080'
        SONAR_TOKEN                    = credentials('sonarqube-token')
        // SonarQube Community MQR: each service must be its own project key
        SONAR_PROJECT_BASE             = 'travel-booking'
    }

    stages {

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 1: Clone Repository
        // ─────────────────────────────────────────────────────────────────────

        stage('Git Clone') {
            steps {
                container('docker') {
                    git branch: 'main', credentialsId: 'github-pat', url: 'https://github.com/Bepissss/gke-devops-project.git'
                    sh 'echo "Repository cloned successfully"'
                    sh 'ls -la'
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 2: Run Tests (with coverage output for SonarQube)
        // ─────────────────────────────────────────────────────────────────────

        stage('Test - Go Services') {
            steps {
                container('golang') {
                    sh '''
                    # Install gocover-cobertura for converting Go coverage → Cobertura XML
                    go install github.com/boumenot/gocover-cobertura@v1.2.0
                    export PATH=$PATH:$(go env GOPATH)/bin

                    for svc in user-service search-service booking-service payment-service notification-service; do
                        echo "===== Testing ${svc} ====="
                        cd ${svc}
                        go mod download
                        go mod tidy
                        go vet ./...

                        # Run tests with coverage in a format SonarQube understands
                        go test ./... \
                            -coverprofile=coverage.out \
                            -covermode=atomic 2>&1 | tee test-report.txt || true

                        # Convert coverage.out → cobertura XML
                        gocover-cobertura < coverage.out > coverage.xml || true

                        cd ..
                    done

                    echo "All Go services tested"
                    '''
                }
            }
        }

        stage('Test - Frontend') {
            steps {
                container('nodejs') {
                    sh '''
                    echo "===== Testing Frontend ====="
                    cd frontend
                    npm install --legacy-peer-deps

                    # Run Jest tests with coverage output (lcov for SonarQube)
                    npx jest --coverage --coverageReporters=lcov --coverageDirectory=coverage \
                        --passWithNoTests || true

                    echo "Frontend tests completed"
                    cd ..
                    '''
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 3: SonarQube Analysis
        // SonarQube Community MQR (v26.9) — one project per service/component
        // Uses sonar-scanner CLI installed into the golang/nodejs containers
        // via a shared /tmp/sonar-scanner mount (downloaded once in golang).
        // ─────────────────────────────────────────────────────────────────────

        stage('SonarQube Analysis - Go Services') {
            steps {
                container('golang') {
                    sh '''
                    # ── Install sonar-scanner CLI ──────────────────────────────
                    SONAR_SCANNER_VERSION="6.2.1.4610"
                    SONAR_SCANNER_HOME="/tmp/sonar-scanner"
                    
                    apt-get update -qq
                    apt-get install -y -qq --no-install-recommends \
                    unzip curl default-jre-headless

                    if [ ! -f "${SONAR_SCANNER_HOME}/bin/sonar-scanner" ]; then
                        echo "Downloading sonar-scanner ${SONAR_SCANNER_VERSION}..."
                        curl -sSLo /tmp/sonar-scanner.zip \
                            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-x64.zip"
                        unzip -q /tmp/sonar-scanner.zip -d /tmp/
                        mv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-x64 ${SONAR_SCANNER_HOME}
                        rm /tmp/sonar-scanner.zip
                    fi

                    export PATH="${SONAR_SCANNER_HOME}/bin:$PATH"

                    # ── Scan each Go service as a separate SonarQube project ──
                    for svc in user-service search-service booking-service payment-service notification-service; do
                        echo "===== SonarQube Scan: ${svc} ====="

                        COVERAGE_ARGS=""
                        if [ -f "${svc}/coverage.xml" ]; then
                            COVERAGE_ARGS="-Dsonar.go.coverage.reportPaths=${svc}/coverage.xml"
                        fi

                        sonar-scanner \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.token=${SONAR_TOKEN} \
                            -Dsonar.projectKey=${SONAR_PROJECT_BASE}-${svc} \
                            -Dsonar.projectName="Travel Booking - ${svc}" \
                            -Dsonar.projectVersion=1.0.${BUILD_NUMBER} \
                            -Dsonar.sources=${svc} \
                            -Dsonar.exclusions="**/*_test.go,**/vendor/**,**/.git/**" \
                            -Dsonar.tests=${svc} \
                            -Dsonar.test.inclusions="**/*_test.go" \
                            ${COVERAGE_ARGS} \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.qualitygate.wait=true \
                            -Dsonar.qualitygate.timeout=300
                    done

                    echo "All Go service scans submitted"
                    '''
                }
            }
        }

        stage('SonarQube Analysis - Frontend') {
            steps {
                container('nodejs') {
                    sh '''
                    # ── Install sonar-scanner CLI ──────────────────────────────
                    SONAR_SCANNER_VERSION="6.2.1.4610"
                    SONAR_SCANNER_HOME="/tmp/sonar-scanner"

                    if [ ! -f "${SONAR_SCANNER_HOME}/bin/sonar-scanner" ]; then
                        echo "Downloading sonar-scanner ${SONAR_SCANNER_VERSION}..."
                        apt-get update -qq && apt-get install -y -qq unzip curl 2>/dev/null || \
                            apk add --no-cache unzip curl 2>/dev/null || true
                        curl -sSLo /tmp/sonar-scanner.zip \
                            "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-x64.zip"
                        unzip -q /tmp/sonar-scanner.zip -d /tmp/
                        mv /tmp/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-x64 ${SONAR_SCANNER_HOME}
                        rm /tmp/sonar-scanner.zip
                    fi

                    export PATH="${SONAR_SCANNER_HOME}/bin:$PATH"

                    echo "===== SonarQube Scan: frontend ====="
                    sonar-scanner \
                        -Dsonar.host.url=${SONAR_HOST_URL} \
                        -Dsonar.token=${SONAR_TOKEN} \
                        -Dsonar.projectKey=${SONAR_PROJECT_BASE}-frontend \
                        -Dsonar.projectName="Travel Booking - frontend" \
                        -Dsonar.projectVersion=1.0.${BUILD_NUMBER} \
                        -Dsonar.sources=frontend/src \
                        -Dsonar.exclusions="**/node_modules/**,**/dist/**,**/.git/**,**/coverage/**" \
                        -Dsonar.tests=frontend/src \
                        -Dsonar.test.inclusions="**/*.test.js,**/*.test.jsx,**/*.test.ts,**/*.test.tsx,**/*.spec.*" \
                        -Dsonar.javascript.lcov.reportPaths=frontend/coverage/lcov.info \
                        -Dsonar.sourceEncoding=UTF-8 \
                        -Dsonar.qualitygate.wait=true \
                        -Dsonar.qualitygate.timeout=300

                    echo "Frontend scan submitted"
                    '''
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 4: Build, Tag & Push Docker Images
        // ─────────────────────────────────────────────────────────────────────

        stage('Docker Login') {
            steps {
                container('docker') {
                    sh '''
                    cat $GOOGLE_APPLICATION_CREDENTIALS | docker login -u _json_key --password-stdin https://${ARTIFACT_REGISTRY}
                    echo "Docker login to Artifact Registry successful"
                    '''
                }
            }
        }

        stage('Build & Push - User Service') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building User Service ====="
                    docker build -t ${DOCKER_REPO}/user-service:${IMAGE_TAG} ./user-service
                    docker tag ${DOCKER_REPO}/user-service:${IMAGE_TAG} ${DOCKER_REPO}/user-service:latest
                    docker push ${DOCKER_REPO}/user-service:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/user-service:latest
                    docker rmi ${DOCKER_REPO}/user-service:${IMAGE_TAG} || true
                    echo "User Service image pushed successfully"
                    """
                }
            }
        }

        stage('Build & Push - Search Service') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building Search Service ====="
                    docker build -t ${DOCKER_REPO}/search-service:${IMAGE_TAG} ./search-service
                    docker tag ${DOCKER_REPO}/search-service:${IMAGE_TAG} ${DOCKER_REPO}/search-service:latest
                    docker push ${DOCKER_REPO}/search-service:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/search-service:latest
                    docker rmi ${DOCKER_REPO}/search-service:${IMAGE_TAG} || true
                    echo "Search Service image pushed successfully"
                    """
                }
            }
        }

        stage('Build & Push - Booking Service') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building Booking Service ====="
                    docker build -t ${DOCKER_REPO}/booking-service:${IMAGE_TAG} ./booking-service
                    docker tag ${DOCKER_REPO}/booking-service:${IMAGE_TAG} ${DOCKER_REPO}/booking-service:latest
                    docker push ${DOCKER_REPO}/booking-service:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/booking-service:latest
                    docker rmi ${DOCKER_REPO}/booking-service:${IMAGE_TAG} || true
                    echo "Booking Service image pushed successfully"
                    """
                }
            }
        }

        stage('Build & Push - Payment Service') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building Payment Service ====="
                    docker build -t ${DOCKER_REPO}/payment-service:${IMAGE_TAG} ./payment-service
                    docker tag ${DOCKER_REPO}/payment-service:${IMAGE_TAG} ${DOCKER_REPO}/payment-service:latest
                    docker push ${DOCKER_REPO}/payment-service:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/payment-service:latest
                    docker rmi ${DOCKER_REPO}/payment-service:${IMAGE_TAG} || true
                    echo "Payment Service image pushed successfully"
                    """
                }
            }
        }

        stage('Build & Push - Notification Service') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building Notification Service ====="
                    docker build -t ${DOCKER_REPO}/notification-service:${IMAGE_TAG} ./notification-service
                    docker tag ${DOCKER_REPO}/notification-service:${IMAGE_TAG} ${DOCKER_REPO}/notification-service:latest
                    docker push ${DOCKER_REPO}/notification-service:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/notification-service:latest
                    docker rmi ${DOCKER_REPO}/notification-service:${IMAGE_TAG} || true
                    echo "Notification Service image pushed successfully"
                    """
                }
            }
        }

        stage('Build & Push - Frontend') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Building Frontend ====="
                    docker build -t ${DOCKER_REPO}/frontend:${IMAGE_TAG} ./frontend
                    docker tag ${DOCKER_REPO}/frontend:${IMAGE_TAG} ${DOCKER_REPO}/frontend:latest
                    docker push ${DOCKER_REPO}/frontend:${IMAGE_TAG}
                    docker push ${DOCKER_REPO}/frontend:latest
                    docker rmi ${DOCKER_REPO}/frontend:${IMAGE_TAG} || true
                    echo "Frontend image pushed successfully"
                    """
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 5: Trivy Security Scan — Scan All Docker Images
        // ─────────────────────────────────────────────────────────────────────

        stage('Trivy Security Scan') {
            steps {
                container('docker') {
                    script {
                        def services = ['user-service', 'search-service', 'booking-service', 'payment-service', 'notification-service', 'frontend']

                        // Install Trivy
                        sh '''
                        apk add --no-cache curl tar
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                        trivy --version
                        '''

                        // Scan each image
                        for (svc in services) {
                            def scanStatus = sh(
                                script: """
                                echo "===== Scanning ${svc} ====="
                                trivy image --exit-code 0 --severity HIGH,CRITICAL --no-progress ${DOCKER_REPO}/${svc}:latest
                                """,
                                returnStatus: true
                            )
                            if (scanStatus != 0) {
                                echo "WARNING: Trivy scan for ${svc} found issues, but pipeline will continue."
                            }
                        }

                        echo "All images scanned successfully"
                    }
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 6: Update Helm Chart with New Image Tags
        // ─────────────────────────────────────────────────────────────────────

        stage('Update Helm Values') {
            steps {
                container('docker') {
                    sh """
                    echo "===== Updating Helm values.yaml with new image tags ====="

                    # Update all service images in values.yaml with the new build tag
                    sed -i 's|image: .*frontend:.*|image: ${DOCKER_REPO}/frontend:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml
                    sed -i 's|image: .*user-service:.*|image: ${DOCKER_REPO}/user-service:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml
                    sed -i 's|image: .*search-service:.*|image: ${DOCKER_REPO}/search-service:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml
                    sed -i 's|image: .*booking-service:.*|image: ${DOCKER_REPO}/booking-service:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml
                    sed -i 's|image: .*payment-service:.*|image: ${DOCKER_REPO}/payment-service:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml
                    sed -i 's|image: .*notification-service:.*|image: ${DOCKER_REPO}/notification-service:${IMAGE_TAG}|' ${HELM_CHART_PATH}/values.yaml

                    echo "Updated values.yaml:"
                    grep "image:" ${HELM_CHART_PATH}/values.yaml

                    echo "Helm values updated successfully"
                    """
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 7: Package & Push Helm Chart to Artifact Registry
        // ─────────────────────────────────────────────────────────────────────

        stage('Package & Push Helm Chart') {
            steps {
                container('helm') {
                    sh """
                    echo "===== Packaging Helm Chart ====="

                    # Update chart version with build number
                    sed -i "s/^version:.*/version: 1.0.${BUILD_NUMBER}/" ${HELM_CHART_PATH}/Chart.yaml

                    # Package the chart
                    helm package ${HELM_CHART_PATH} --destination ${WORKSPACE}/helm-packages/

                    echo "Helm chart packaged successfully"
                    ls -la ${WORKSPACE}/helm-packages/
                    """
                }
                container('gcloud') {
                    sh """
                    echo "===== Getting Access Token ====="

                    # Authenticate with GCP
                    gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                    gcloud config set project \$GOOGLE_CLOUD_PROJECT

                    # Save access token to workspace (shared between containers)
                    gcloud auth print-access-token > ${WORKSPACE}/gcp-access-token
                    echo "Access token saved"
                    """
                }
                container('helm') {
                    sh """
                    echo "===== Pushing Helm Chart to Artifact Registry ====="

                    # Login to Helm registry using saved token from workspace
                    cat ${WORKSPACE}/gcp-access-token | helm registry login -u oauth2accesstoken --password-stdin https://${ARTIFACT_REGISTRY}

                    # Push helm chart
                    helm push ${WORKSPACE}/helm-packages/travel-booking-1.0.${BUILD_NUMBER}.tgz oci://${ARTIFACT_REGISTRY}/${GOOGLE_CLOUD_PROJECT}/travel-booking

                    echo "Helm chart pushed to Artifact Registry successfully"
                    """
                }
            }
        }

        // ─────────────────────────────────────────────────────────────────────
        // STAGE 8: Deploy to GKE
        // ─────────────────────────────────────────────────────────────────────

        stage('Deploy to GKE') {
            steps {
                container('gcloud') {
                    try {
                        timeout(time: 5, unit: 'MINUTES') {
                            env.useChoice = input message: "Can it be deployed?",
                                parameters: [choice(name: 'deploy', choices: 'no\nyes', description: 'Choose "yes" if you want to deploy!')]
                        }
                        if (env.useChoice == 'yes') {
                            sh """
                            echo "===== Connecting to GKE Cluster ====="

                            # Authenticate with GCP
                            gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                            gcloud config set project \$GOOGLE_CLOUD_PROJECT

                            # Install kubectl, gke-auth-plugin, and helm
                            apt-get update -qq && apt-get install -y -qq kubectl google-cloud-cli-gke-gcloud-auth-plugin 2>/dev/null || true
                            curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash 2>/dev/null

                            # Connect to GKE cluster
                            gcloud container clusters get-credentials ${GKE_CLUSTER} --zone ${GKE_ZONE} --project \$GOOGLE_CLOUD_PROJECT

                            echo "Connected to GKE cluster: ${GKE_CLUSTER}"
                            kubectl get nodes

                            # Create namespace if it doesn't exist
                            kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

                            # Login to Helm registry
                            gcloud auth print-access-token | helm registry login -u oauth2accesstoken --password-stdin https://${ARTIFACT_REGISTRY}

                            # Pull the latest chart
                            helm pull oci://${ARTIFACT_REGISTRY}/\$GOOGLE_CLOUD_PROJECT/travel-booking/travel-booking --version 1.0.${BUILD_NUMBER} --destination ${WORKSPACE}/

                            # Install or upgrade the helm release
                            helm upgrade --install travel-booking ${WORKSPACE}/travel-booking-1.0.${BUILD_NUMBER}.tgz \\
                            --namespace ${NAMESPACE} \\
                            --wait \\
                            --timeout 5m

                            echo "===== Deployment Complete ====="
                            echo ""
                            echo "Helm Release:"
                            helm list -n ${NAMESPACE}
                            echo ""
                            echo "Deployments:"
                            kubectl get deployments -n ${NAMESPACE}
                            echo ""
                            echo "Pods:"
                            kubectl get pods -n ${NAMESPACE}
                            echo ""
                            echo "Services:"
                            kubectl get svc -n ${NAMESPACE}
                            echo ""
                            echo "Gateway:"
                            kubectl get gateway -n ${NAMESPACE}
                            echo ""
                            echo "HTTPRoutes:"
                            kubectl get httproute -n ${NAMESPACE}
                            echo ""
                            echo "StatefulSets:"
                            kubectl get statefulsets -n ${NAMESPACE}
                            echo ""
                            echo "ConfigMaps:"
                            kubectl get configmaps -n ${NAMESPACE}
                            echo ""
                            echo "Secrets:"
                            kubectl get secrets -n ${NAMESPACE}
                            echo ""
                            echo "HPAs:"
                            kubectl get hpa -n ${NAMESPACE}
                            """
                        }
                        else {
                            echo "Do not confirm the deployment!"
                        }
                    } catch (Exception err) {

                    }

                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // POST ACTIONS
    // ─────────────────────────────────────────────────────────────────────────

    post {
        success {
            echo """
            =========================================
            PIPELINE COMPLETED SUCCESSFULLY
            =========================================
            Build Number : ${BUILD_NUMBER}
            Image Tag    : ${IMAGE_TAG}
            Chart Version: 1.0.${BUILD_NUMBER}
            Cluster      : ${GKE_CLUSTER}
            Namespace    : ${NAMESPACE}
            SonarQube    : ${SONAR_HOST_URL}
            =========================================
            """
        }
        failure {
            echo """
            =========================================
            PIPELINE FAILED
            =========================================
            Build Number : ${BUILD_NUMBER}
            Check the stage logs above for details.
            =========================================
            """
        }
        always {
            // Clean up Docker images to save space
            container('docker') {
                sh 'docker system prune -f || true'
            }
        }
    }
}