#!/usr/bin/env bash

set -euo pipefail

REGION="ap-southeast-1"

INSTANCE_IDS=(
    "i-091cd8472549dceb4"  # Jenkins
    "i-0bece7246f9d9d113"  # SonarQube
    "i-0149579e1969217ba"  # Nexus
)

show_status() {
    aws ec2 describe-instances \
        --instance-ids "${INSTANCE_IDS[@]}" \
        --region "$REGION" \
        --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,Status:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress}' \
        --output table \
        --no-cli-pager
}

case "${1:-status}" in

    start)
        echo "Starting all DevOps machines..."

        aws ec2 start-instances \
            --instance-ids "${INSTANCE_IDS[@]}" \
            --region "$REGION" \
            --no-cli-pager > /dev/null

        echo "Waiting for EC2 status checks..."

        aws ec2 wait instance-status-ok \
            --instance-ids "${INSTANCE_IDS[@]}" \
            --region "$REGION"

        echo "All EC2 machines are ready!"
        show_status
        ;;

    stop)
        echo "Stopping all DevOps machines..."

        aws ec2 stop-instances \
            --instance-ids "${INSTANCE_IDS[@]}" \
            --region "$REGION" \
            --no-cli-pager > /dev/null

        aws ec2 wait instance-stopped \
            --instance-ids "${INSTANCE_IDS[@]}" \
            --region "$REGION"

        echo "All EC2 machines stopped!"
        show_status
        ;;

    restart)
        echo "Rebooting all DevOps machines..."

        aws ec2 reboot-instances \
            --instance-ids "${INSTANCE_IDS[@]}" \
            --region "$REGION" \
            --no-cli-pager

        echo "Reboot request submitted."
        ;;

    status)
        show_status
        ;;

    *)
        echo "Usage: $0 {start|stop|restart|status}"
        exit 1
        ;;

esac
