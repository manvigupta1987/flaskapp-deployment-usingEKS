# Deploying a Flask API

In this Flask app, we containerized and deployed a Flask API to a Kubernetes cluster using Docker, AWS EKS, CodePipeline, and CodeBuild.

This app consists of a simple API with three endpoints:

- `GET '/'`: This is a simple health check, which returns the response 'Healthy'. 
- `POST '/auth'`: This takes a email and password as json arguments and returns a JWT based on a custom secret.
- `GET '/contents'`: This requires a valid JWT, and returns the un-encrpyted contents of that token. 

The app relies on a secret set as the environment variable `JWT_SECRET` to produce a JWT. 
The built-in Flask server is adequate for local development, but not production, so you will be using the production-ready [Gunicorn](https://gunicorn.org/) server when deploying the app.

## Dependencies
- Docker Engine
- AWS Account
     
## Steps to deploy app to EKS
1. Write a Dockerfile
2. Build and test the container locally
3. Create an EKS cluster
    
    1. `eksctl create cluster --name <cluster-name>`
    2. Set following enviornment variables:
        `export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)`
        `export TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"`
        `echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": [ "eks:Describe*", "ssm:GetParameters" ], "Resource": "*" } ] }' > /tmp/iam-role-policy` --> created a policy document
        `aws iam put-role-policy --role-name UdacityFlaskDeployCBKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy` --> attach the policy to `UdacityFlaskDeployCBKubectlRole` role
    3.  Get the current config map and save it to a file:
        `kubectl get -n kube-system configmap/aws-auth -o yaml > /tmp/aws-auth-patch.yml`
        `kubectl patch configmap/aws-auth -n kube-system --patch "$(cat /tmp/aws-auth-patch.yml)"`
  
4. Store a secret using AWS Parameter Store
    1. Added the env with parameter store in the buildspec.yaml
    2. aws ssm put-parameter --name JWT_SECRET --value "YourJWTSecret" --type SecureString --> put secret to AWS parameter store
5. Create a CodePipeline triggered by GitHub check ins
    1. Modified the ci-cd-codepipeline.cfn.yml file with the GitHub and Cluster information. 
6. Create a CodeBuild stage which will build, test, and deploy your code
    1. Created a stack in cloud formation using the file ci-cd-codepipeline.cfn.yml. 
    2. `kubectl get services <cluster-name> -o wide` --> used to get the external ip for service. 


## Commands used to test API endpoints
1. export TOKEN=`curl -d '{"email":"<EMAIL>","password":"<PASSWORD>"}' -H "Content-Type: application/json" -X POST localhost:8080/auth  | jq -r '.token'`
2. curl --request GET 'http://127.0.0.1:8080/contents' -H "Authorization: Bearer ${TOKEN}" | jq .


