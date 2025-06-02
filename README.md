# knot-takehome

This project demonstrates deploying a simple Flask web server with Terraform and Docker. The application intentionally returns a 500 error for 20% of requests.

## Install prerequisites

1. On OSX or Linux with brew: 

```shell
brew install awscli tfenv
cd terraform/aws
tfenv install
```

You should also have a working Docker daemon

On Linux, I still recommend [tfenv](https://github.com/tfutils/tfenv)

2. configure aws with an IAM keypair

```shell
aws configure
```

## Initialize Terraform

1. Make an S3 bucket in the console
2. Follow these instructions
```shell
TFSTATE_BUCKET=<My bucket>

# Optional

# The statefile path inside your bucket
TFSTATE_KEY=<something>.tfvars

# The region your S3 bucket is in (Default: us-east-2)
TFSTATE_REGION=us-east-1

cd terraform/

# Only set the variables you set as env vars
terraform init \
-backend-config="bucket=${TFSTATE_BUCKET}" \
-backend-config="key=${TFSTATE_KEY}" \
-backend-config="region=${TFSTATE_REGION}" \

terraform apply

# If you want to set ssh:
echo 'ssh_cidr_blocks=["a.b.c.d/#"]' > tmp.tfvars
terraform apply -var-file tmp.tfvars
```


## Setup
1. Build the Docker image:
   ```shell
   docker build -t myflask:latest .
   ```
2. Push the image to a registry accessible by the EC2 instance (e.g., ECR).
3. Update `terraform/terraform.tfvars` with the AMI, region, and image reference.
4. Initialize and apply Terraform:
   ```shell
   cd terraform
   terraform init
   terraform apply
   ```

## Simulating Errors
The Flask server returns a 500 status code randomly 20% of the time. Access the instance's IP address in a browser or via curl multiple times to observe intermittent failures.

## Mitigation Testing
Remove or adjust the error simulation in `app/app.py`, rebuild the Docker image, and redeploy. Verify that 5xx errors no longer occur.

See `incident_report.md` for details of the investigation and mitigation.
