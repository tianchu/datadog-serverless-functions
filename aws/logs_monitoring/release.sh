#!/bin/bash

set -e

# Determine the S3 bucket to publish the template
if [ -z "$1" ]; then
    echo "Must specify a S3 bucket to publish the template"
    exit 1
else
    BUCKET=$1
fi

VERSION=$(grep -o 'Version: \d\.\d\.\d' template.yaml | cut -d' ' -f2)

# Validate the template
echo "Validating template.yaml"
aws cloudformation validate-template --template-body file://template.yaml

# Confirm to proceed
read -p "About to create a Github release aws-dd-forwarder-${VERSION} and upload the template.yaml to s3://${BUCKET}/templates/${VERSION}.yaml. Continue (y/n)?" CONT
if [ "$CONT" != "y" ]; then
  echo "Exiting"
  exit 1
fi

# Create a github release
echo "Release aws-dd-forwarder-${VERSION} to github"
go get github.com/github/hub
zip -r function.zip .
hub release create -a function.zip -m "aws-dd-forwarder-${VERSION}" aws-dd-forwarder-${VERSION}

# Upload the template to the S3 bucket
echo "Uploading template.yaml to s3://${BUCKET}/templates/${VERSION}.yaml"
aws s3 cp template.yaml s3://${BUCKET}/templates/${VERSION}.yaml --grants read=uri=http://acs.amazonaws.com/groups/global/AllUsers
echo "Done uploading the template, and here is the CloudFormation quick launch URL"
echo "https://console.aws.amazon.com/cloudformation/home#/stacks/new?stackName=datadog-serverless&templateURL=https://${BUCKET}.s3.amazonaws.com/templates/${VERSION}.yaml"

echo "Done!"
