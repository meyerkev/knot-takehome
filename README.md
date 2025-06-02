# knot-takehome

This project demonstrates deploying a simple Flask web server with Terraform and Docker. The application intentionally returns a 500 error for 20% of requests.

## Prerequisites
- Terraform >= 1.3
- Docker
- AWS credentials configured

## Setup
1. Build the Docker image:
   ```sh
   docker build -t myflask:latest .
   ```
2. Push the image to a registry accessible by the EC2 instance (e.g., ECR).
3. Update `terraform/terraform.tfvars` with the AMI, region, and image reference.
4. Initialize and apply Terraform:
   ```sh
   cd terraform
   terraform init
   terraform apply
   ```

## Simulating Errors
The Flask server returns a 500 status code randomly 20% of the time. Access the instance's IP address in a browser or via curl multiple times to observe intermittent failures.

## Mitigation Testing
Remove or adjust the error simulation in `app/app.py`, rebuild the Docker image, and redeploy. Verify that 5xx errors no longer occur.

See `incident_report.md` for details of the investigation and mitigation.
