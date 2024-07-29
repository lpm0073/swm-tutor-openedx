#------------------------------------------------------------------------------
# written by: Lawrence McDaniel - https://lawrencemcdaniel.com
# date: Jul-2024
#
# Tutor Open edX deployment script for Stepwise Math - Palm
# This script is used to deploy the Stepwise Math Open edX platform
# to a local Ubuntu 20.04 LTS server. The script assumes that the
# server has been configured with the necessary dependencies and
# that the tutor environment has been installed.
#
# The script will:
# 1. Load environment variables from the .env file
# 2. Fetch AWS credentials from the AWS CLI configuration
# 3. Install the necessary tutor plugins
# 4. Configure the tutor environment
# 5. Start the tutor environment
#
#------------------------------------------------------------------------------

# Load environment variables from .env file
if [ -f .env ]; then
    source .env
else
    echo ".env file not found!"
    exit 1
fi

# Fetch AWS credentials from AWS CLI configuration. These
# will be used both in the openedx configuration as well as
# locally in the ubuntu environment so that we can pull the 
# private docker images from the AWS ECR repository.
export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
export AWS_DEFAULT_REGION=us-east-2

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "AWS credentials not found in AWS CLI configuration!"
    exit 1
fi

# login to the AWS ECR repository
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 090511222473.dkr.ecr.us-east-2.amazonaws.com

# Install the necessary tutor plugins
# -------------------------------------
# pip install git+https://github.com/lpm0073/tutor-contrib-codejail@mcdaniel-202401
pip install git+https://github.com/cookiecutter-openedx/tutor-contrib-s3
tutor plugins enable codejail
tutor plugins enable s3
tutor config save

# Use the openedx container image from the AWS ECR repository
# -------------------------------------
tutor config save --set DOCKER_IMAGE_OPENEDX=090511222473.dkr.ecr.us-east-2.amazonaws.com/stepwisemath/openedx-v16-staging:latest \

# Port the configuration settings from k8s to the tutor environment
# -------------------------------------
tutor config save --set OPENEDX_SECRET_KEY=$OPENEDX_SECRET_KEY \
                --set JWT_RSA_PRIVATE_KEY=$JWT_PRIVATE_KEY \
                --set CMS_OAUTH2_SECRET=$CMS_OAUTH2_SECRET \
                --set OPENEDX_COMMON_VERSION=open-release/palm.4 \

tutor config save --set CODEJAIL_ENFORCE_APPARMOR=true \
                --set CODEJAIL_ENABLE_K8S_DAEMONSET=true \
                --set CODEJAIL_SKIP_INIT=false \
                --set CODEJAIL_EXTRA_PIP_REQUIREMENTS='BytesIO,base64,fractions,math,matplotlib,numpy,random' \

# configure aws s3 remote storages
# -------------------------------------
tutor config save --set OPENEDX_AWS_ACCESS_KEY="$AWS_ACCESS_KEY_ID" \
                    --set OPENEDX_AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
                    --set OPENEDX_AWS_QUERYSTRING_AUTH="False" \
                    --set OPENEDX_AWS_S3_SECURE_URLS="False" \
                    --set OPENEDX_MEDIA_ROOT="openedx/media/" \
                    --set S3_STORAGE_BUCKET="swm-openedx-us-staging-storage" \
                    --set S3_CUSTOM_DOMAIN="cdn.staging.stepwisemath.ai" \
                    --set S3_REGION="us-east-2" \

# configure aws ses email settings
# -------------------------------------
tutor config save --set RUN_SMTP=false \
                --set SMTP_HOST=email-smtp.us-east-2.amazonaws.com \
                --set SMTP_PASSWORD=$SMTP_PASSWORD \
                --set SMTP_PORT=587 \
                --set SMTP_USE_SSL=false \
                --set SMTP_USE_TLS=true \
                --set SMTP_USERNAME=$SMTP_USERNAME \
                
# configure aws rds mysql database settings
# -------------------------------------
tutor config save --set RUN_MYSQL=false \
                --set MYSQL_HOST=mysql.service.lawrencemcdaniel.com \
                --set MYSQL_PORT=3306 \
                --set OPENEDX_MYSQL_DATABASE=swmopenedx_staging_edx \
                --set OPENEDX_MYSQL_USERNAME=$OPENEDX_MYSQL_USERNAME \
                --set OPENEDX_MYSQL_PASSWORD=$OPENEDX_MYSQL_PASSWORD \
                --set MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD \
                --set MYSQL_ROOT_USERNAME=$MYSQL_ROOT_USERNAME \

# configure aws ec2 mongodb database settings
# -------------------------------------
tutor config save --set RUN_MONGODB=false \
                --set MONGODB_HOST=mongodb.service.lawrencemcdaniel.com \
                --set MONGODB_PORT=27017 \
                --set MONGODB_ADMIN_PASSWORD=$MONGODB_ADMIN_PASSWORD \
                --set MONGODB_ADMIN_USERNAME=admin \
                --set OPENEDX_MONGODB_DB=swmopenedx_staging_edx \
                --set OPENEDX_MONGODB_PASSWORD="" \
                --set OPENEDX_MONGODB_USERNAME="" \

# configure tutor caddy
# -------------------------------------
tutor config save --set ENABLE_WEB_PROXY=true \
                  --set ENABLE_HTTPS=true \

# set the custom theme
# -------------------------------------
tutor local do settheme stepwise-edx-theme


# cleanup docker environment. this should result in a no-op
# unless mysql and/or mongodb are present in the docker environment
# -------------------------------------
docker system prune -a --volumes
docker volume prune -f
docker builder prune -a -f

# startup open edx
tutor local start
