#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

source_env

generate_ec2_list_0 () {
    EC2_LIST=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names 'Farm-1' --region $AWS_REGION --profile $AWS_PROFILE | jq -r '.AutoScalingGroups | .[] | .Instances | .[] | .InstanceId')
    ec2_array=(${EC2_LIST/// })
    echo "Task ID List:"
    echo ""
    for i in "${!ec2_array[@]}"
        do
            echo "EC2 ID $i = ${ec2_array[i]}"
        done
}

generate_ec2_list_1 () {
    EC2_LIST=$(aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names 'Farm-2' --region $AWS_REGION --profile $AWS_PROFILE | jq -r '.AutoScalingGroups | .[] | .Instances | .[] | .InstanceId')
    ec2_array=(${EC2_LIST/// })
    echo "Task ID List:"
    echo ""
    for i in "${!ec2_array[@]}"
        do
            echo "EC2 ID $i = ${ec2_array[i]}"
        done
}


PS3='Please enter an action: '
OPTIONS=(
    "Connect to EC2 Instance on Farm-1"
    "Connect to EC2 Instance on Farm-2"
    "Quit"
    )

select opt in "${OPTIONS[@]}"
do
    case $opt in
        "Connect to EC2 Instance on Farm-1")
            generate_ec2_list_0
            echo -e '\n'
            read -p "Enter the EC2 instance ID (Copy and paste one of the above): " EC2_ID
            echo -e '\n'
            aws ssm start-session --target "$EC2_ID" --region $AWS_REGION --profile $AWS_PROFILE
            exit 0
        ;;
        "Connect to EC2 Instance on Farm-2")
            generate_ec2_list_1
            echo -e '\n'
            read -p "Enter the EC2 instance ID (Copy and paste one of the above): " EC2_ID
            echo -e '\n'
            aws ssm start-session --target "$EC2_ID" --region $AWS_REGION --profile $AWS_PROFILE
            exit 0
        ;;
        "Quit")
            echo "Script ended"
            break
            ;;
        *)
            echo "$REPLY is not a valid parameter"
            exit 1
            ;;
    esac
done