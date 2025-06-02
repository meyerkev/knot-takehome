# knot-takehome

This project demonstrates deploying a simple Flask web server with Terraform and Docker. The application intentionally returns a 500 error for 20% of requests.

## Install prerequisites

1. On OSX or Linux with brew: 

```shell
brew install awscli tfenv
cd terraform
tfenv install
tfenv use
cd ..
```

You should also have a working Docker daemon

On Linux, I still recommend [tfenv](https://github.com/tfutils/tfenv)

2. configure aws with an IAM keypair that is an admin or close to it.  

```shell
aws configure
```

## Initialize Terraform

1. Make an S3 bucket in the console that you can use to hold Terraform state.  
2. Follow these instructions

```shell
export TF_STATE_BUCKET=<My bucket>
# Optional

# The statefile path inside your bucket
export TF_STATE_KEY=<something>.tfvars

# The region your S3 bucket is in (Default: us-east-2)
export TF_STATE_REGION=us-east-1

# Set your cidr
export SSH_CIDR_BLOCK="0.0.0.0/0"

# run the setup script
./zero_to_hero.sh
```

The terraform outputs at the end will provide a URL as well as instructions to SSH into the file servers if something went wrong.    

It will look something like this: 

```
terraform output -raw private_key > ~/.ssh/knot-takehome.pem
    
# Set correct permissions
chmod 600 ~/.ssh/knot-takehome.pem
    
# Add to SSH agent
ssh-add ~/.ssh/knot-takehome.pem
    
# SSH command (after key is added)
ssh -o StrictHostKeyChecking=no -A ubuntu@18.119.255.51

🔍 You can access the application at: http://18.119.255.51
```

