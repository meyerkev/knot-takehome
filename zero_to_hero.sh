#!/bin/bash
set -eo pipefail

cd $(dirname $0)

echo "🚀 Starting zero to hero deployment..."

TERRAFORM_INIT_ARGS=''
if [ ! -z "$TF_STATE_BUCKET" ]; then
    TERRAFORM_INIT_ARGS="--backend-config=bucket=$TF_STATE_BUCKET"
fi
if [ ! -z "$TF_STATE_KEY" ]; then
    TERRAFORM_INIT_ARGS="$TERRAFORM_INIT_ARGS --backend-config=key=$TF_STATE_KEY"
fi
if [ ! -z "$TF_STATE_REGION" ]; then
    TERRAFORM_INIT_ARGS="$TERRAFORM_INIT_ARGS --backend-config=region=$TF_STATE_REGION"
fi

TFVARS=""
if [ ! -z "$SSH_CIDR_BLOCK" ]; then
    # Create a temporary file for the list
    TEMP_FILE=$(mktemp)
    echo "ssh_cidr_blocks = [\"$SSH_CIDR_BLOCK\"]" > "$TEMP_FILE"
    TFVARS="$TFVARS -var-file=$TEMP_FILE"
    # Clean up temp file after terraform runs
    trap 'rm -f "$TEMP_FILE"' EXIT
fi

set -u

# Initialize and apply Terraform
echo "📦 Creating infrastructure with Terraform..."
cd terraform/bootstrap
terraform init $TERRAFORM_INIT_ARGS
terraform apply -auto-approve

echo "✨ Infrastructure created successfully!"

# Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd ../../app
make build push
IMAGE_ID=$(make output-image-id)

echo "🔍 Image ID: $IMAGE_ID"

cd ../terraform
terraform init $TERRAFORM_INIT_ARGS
terraform apply -var "docker_image=$IMAGE_ID" $TFVARS -auto-approve

timeout=300  # 5 minutes in seconds
start_time=$(date +%s)
end_time=$((start_time + timeout))

current_time=$(date +%s)
while ! curl -s $(terraform output -raw instance_ip) > /dev/null; do
    current_time=$(date +%s)
    if [ $current_time -ge $end_time ]; then
        echo "Timeout reached after 5 minutes. Application may not be ready."
        break
    fi
    echo "Waiting for application to start... $(date)"
    sleep 10
done

EXIT_CODE=0
if [ $current_time -ge $end_time ]; then
    echo "Timeout reached after 5 minutes. Application may not be ready."
    EXIT_CODE=1
else
    echo "🎉 Deployment complete!"
fi

echo "🔑 To SSH into the instance, run:"
echo "    $(terraform output -raw ssh_key_commands)"

echo
echo "🔍 You can access the application at: http://$(terraform output -raw instance_ip)"

exit $EXIT_CODE
