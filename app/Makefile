# Variables
AWS_REGION ?= us-east-2
ECR_REPO_NAME = knot-takehome
IMAGE_TAG ?= latest

# Get AWS account ID and ECR repository URL
ECR_REPO_URL := $(shell aws ecr describe-repositories --repository-names $(ECR_REPO_NAME) --region $(AWS_REGION) --query 'repositories[0].repositoryUri' --output text)

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the Docker image locally
	docker build --platform linux/amd64 -t $(ECR_REPO_NAME):$(IMAGE_TAG) .

.PHONY: run
run: ## Run the application locally
	docker run -p 8000:8000 $(ECR_REPO_NAME):$(IMAGE_TAG)

.PHONY: ecr-login
ecr-login: ## Login to ECR
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REPO_URL)

.PHONY: push
push: ecr-login ## Push the image to ECR
	docker tag $(ECR_REPO_NAME):$(IMAGE_TAG) $(ECR_REPO_URL):$(IMAGE_TAG)
	docker push $(ECR_REPO_URL):$(IMAGE_TAG)

.PHONY: pull
pull: ecr-login ## Pull the image from ECR
	docker pull $(ECR_REPO_URL):$(IMAGE_TAG)

.PHONY: clean
clean: ## Remove local Docker images
	-docker rmi $(ECR_REPO_NAME):$(IMAGE_TAG)
	-docker rmi $(ECR_REPO_URL):$(IMAGE_TAG)

.PHONY: deploy
deploy: build push ## Build and push to ECR in one command

.PHONY: list-tags
list-tags: ## List all image tags in ECR
	aws ecr list-images --repository-name $(ECR_REPO_NAME) --region $(AWS_REGION) --query 'imageIds[*].imageTag' --output table

.PHONY: output-repository-url
output-image-id: ## Output the image ID
	@echo $(ECR_REPO_URL):$(IMAGE_TAG)
