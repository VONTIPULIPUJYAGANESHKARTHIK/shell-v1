#!/bin/bash

ami_id="ami-0055977a6e828a4f4"
instance_type="t3.micro"
domain_name="gcart.store"
hostedzone_id="Z01591623E51DMT4FH925"

for instance in "$@"
do
    echo "Creating instance = $instance"

    # Create EC2 instance
    instance_id=$(aws ec2 run-instances \
        --image-id "$ami_id" \
        --instance-type "$instance_type" \
        --security-groups "roboshop-common" "roboshop-$instance" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=roboshop-$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text) || {
            echo "Failed to create instance: $instance"
            continue
        }

    echo "$instance ID: $instance_id"

    # Wait until instance is running
    aws ec2 wait instance-running \
        --instance-ids "$instance_id" || {
            echo "Instance failed to reach running state: $instance_id"
            continue
        }

    # Retrieve IP address based on instance type
    if [ "$instance" != "frontend" ]; then

        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)

    else

        IP=$(aws ec2 describe-instances \
            --instance-ids "$instance_id" \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)

    fi

    if [ -z "$IP" ] || [ "$IP" = "None" ]; then
        echo "Failed to retrieve IP for $instance"
        continue
    fi

    echo "$instance IP: $IP"

    # Set Route 53 record name
    r53_record_name="$instance.$domain_name"

    # Update Route 53 record
    aws route53 change-resource-record-sets \
        --hosted-zone-id "$hostedzone_id" \
        --change-batch "{
            \"Changes\": [
                {
                    \"Action\": \"UPSERT\",
                    \"ResourceRecordSet\": {
                        \"Name\": \"$r53_record_name\",
                        \"Type\": \"A\",
                        \"TTL\": 60,
                        \"ResourceRecords\": [
                            {
                                \"Value\": \"$IP\"
                            }
                        ]
                    }
                }
            ]
        }"

    if [ $? -eq 0 ]; then
        echo "Route 53 record updated: $r53_record_name -> $IP"
    else
        echo "Failed to update Route 53 record for $instance"
    fi

done