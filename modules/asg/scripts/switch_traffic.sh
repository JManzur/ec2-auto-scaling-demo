#!/bin/bash

source_env () {
    set -e
    set -a
    source .env
}

source_env

PS3='Please enter an action: '
OPTIONS=(
    "Describe State"
    "Switch traffic to Farm-1"
    "Switch traffic to Farm-2"
    "Enable Farm Round-robin"
    "Quit"
    )

select opt in "${OPTIONS[@]}"
do
    case $opt in
        "Describe State")
            aws elbv2 describe-listeners --listener-arns $Listener_ARN --profile $AWS_PROFILE --region $AWS_REGION | jq -r
            exit 0
        ;;
        "Switch traffic to Farm-1")
            aws elbv2 modify-listener --listener-arn $Listener_ARN --default-actions '[{"Type":"forward","Order":1,"ForwardConfig":{"TargetGroups":[{"TargetGroupArn":"'"$Farm1_ARN"'","Weight":1},{"TargetGroupArn":"'"$Farm2_ARN"'","Weight":0}],"TargetGroupStickinessConfig":{"Enabled":false,"DurationSeconds":1}}}]' --profile $AWS_PROFILE --region $AWS_REGION | jq -r
            exit 0
        ;;
        "Switch traffic to Farm-2")
            aws elbv2 modify-listener --listener-arn $Listener_ARN --default-actions '[{"Type":"forward","Order":1,"ForwardConfig":{"TargetGroups":[{"TargetGroupArn":"'"$Farm1_ARN"'","Weight":0},{"TargetGroupArn":"'"$Farm2_ARN"'","Weight":1}],"TargetGroupStickinessConfig":{"Enabled":false,"DurationSeconds":1}}}]' --profile $AWS_PROFILE --region $AWS_REGION | jq -r
            exit 0
        ;;
        "Enable Farm Round-robin")
            aws elbv2 modify-listener --listener-arn $Listener_ARN --default-actions '[{"Type":"forward","Order":1,"ForwardConfig":{"TargetGroups":[{"TargetGroupArn":"'"$Farm1_ARN"'","Weight":1},{"TargetGroupArn":"'"$Farm2_ARN"'","Weight":1}],"TargetGroupStickinessConfig":{"Enabled":false,"DurationSeconds":1}}}]' --profile $AWS_PROFILE --region $AWS_REGION | jq -r
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