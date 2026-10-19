#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="gcart.store"
hostedzone_id="Z01591623E51DMT4FH925"

for instance in "$@"
do
    echo "Creating instance = $instance"

    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-shell}]" \
        --query 'Instances[0].InstanceId' \
        --output text
)

echo "$instance ID = $instance_id"
done