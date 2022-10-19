#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

source_env

PS3='Please enter an action: '
OPTIONS=(
    "Refresh Farm-1"
    "Refresh Farm-2"
    "Quit"
    )

select opt in "${OPTIONS[@]}"
do
    case $opt in
        "Refresh Farm-1")
            echo -e '\n'
            echo "[INFO] Switching traffic to Farm-2"
            sleep 2
            echo -e '\n'
            aws elbv2 modify-listener --listener-arn $Listener_ARN --default-actions '[{"Type":"forward","Order":1,"ForwardConfig":{"TargetGroups":[{"TargetGroupArn":"'"$Farm0_ARN"'","Weight":0},{"TargetGroupArn":"'"$Farm1_ARN"'","Weight":1}],"TargetGroupStickinessConfig":{"Enabled":false,"DurationSeconds":1}}}]' --profile $AWS_PROFILE --region $AWS_REGION | jq -r
            echo -e '\n'
            echo "[INFO] Starting instance refresh process on Farm-1"
            sleep 2
            aws autoscaling  start-instance-refresh --auto-scaling-group-name 'Farm-1' --region $AWS_REGION --profile $AWS_PROFILE | jq -r
            exit 0
        ;;
        "Refresh Farm-2")
            echo "[INFO] Switching traffic to Farm-1"
            sleep 2
            echo -e '\n'
            aws elbv2 modify-listener --listener-arn $Listener_ARN --default-actions '[{"Type":"forward","Order":1,"ForwardConfig":{"TargetGroups":[{"TargetGroupArn":"'"$Farm0_ARN"'","Weight":1},{"TargetGroupArn":"'"$Farm1_ARN"'","Weight":0}],"TargetGroupStickinessConfig":{"Enabled":false,"DurationSeconds":1}}}]' --profile $AWS_PROFILE --region $AWS_REGION | jq -r
            echo -e '\n'
            echo "[INFO] Starting instance refresh process on Farm-2"
            sleep 2
            aws autoscaling  start-instance-refresh --auto-scaling-group-name 'Farm-2' --region $AWS_REGION --profile $AWS_PROFILE | jq -r
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