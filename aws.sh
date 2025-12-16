#!/bin/bash

REGION="us-east-1"

echo ""
echo "======================================"
echo "   AWS Resource Scanner & Cleanup"
echo "   Region: $REGION"
echo "======================================"
echo ""

# EC2 Instances
echo "🖥️  EC2 INSTANCES:"
echo "-------------------"
INSTANCES=$(aws ec2 describe-instances --region $REGION \
    --query 'Reservations[*].Instances[?State.Name!=`terminated`].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output text)

if [ -z "$INSTANCES" ]; then
    echo "   No instances running"
else
    echo "$INSTANCES" | while read id type state name; do
        printf "   %-20s | %-12s | %-10s | %s\n" "$id" "$type" "$state" "$name"
    done
    echo ""
    read -p "   Terminate all EC2 instances? (y/n): " choice
    if [ "$choice" = "y" ]; then
        IDS=$(aws ec2 describe-instances --region $REGION \
            --query 'Reservations[*].Instances[?State.Name!=`terminated`].InstanceId' \
            --output text)
        if [ -n "$IDS" ]; then
            aws ec2 terminate-instances --region $REGION --instance-ids $IDS
            echo "   ✅ Termination initiated"
        fi
    fi
fi
echo ""

# S3 Buckets
echo "🪣 S3 BUCKETS:"
echo "--------------"
BUCKETS=$(aws s3api list-buckets --query 'Buckets[*].Name' --output text)

if [ -z "$BUCKETS" ]; then
    echo "   No buckets found"
else
    for bucket in $BUCKETS; do
        SIZE=$(aws s3 ls s3://$bucket --summarize --recursive 2>/dev/null | tail -1 | awk '{print $3}')
        printf "   %-40s | Size: %s bytes\n" "$bucket" "${SIZE:-0}"
    done
    echo ""
    read -p "   Delete a bucket? Enter name (or 'skip'): " bucket_name
    if [ "$bucket_name" != "skip" ] && [ -n "$bucket_name" ]; then
        echo "   Emptying bucket..."
        aws s3 rm s3://$bucket_name --recursive
        echo "   Deleting bucket..."
        aws s3 rb s3://$bucket_name
        echo "   ✅ Deleted $bucket_name"
    fi
fi
echo ""

# VPCs (non-default)
echo "🌐 NON-DEFAULT VPCs:"
echo "--------------------"
VPCS=$(aws ec2 describe-vpcs --region $REGION \
    --query 'Vpcs[?IsDefault==`false`].[VpcId,CidrBlock,Tags[?Key==`Name`].Value|[0]]' \
    --output text)

if [ -z "$VPCS" ]; then
    echo "   No non-default VPCs"
else
    echo "$VPCS" | while read vpc cidr name; do
        printf "   %-25s | %-18s | %s\n" "$vpc" "$cidr" "$name"
    done
fi
echo ""

# Elastic IPs
echo "📍 ELASTIC IPs:"
echo "---------------"
EIPS=$(aws ec2 describe-addresses --region $REGION \
    --query 'Addresses[*].[PublicIp,AllocationId,InstanceId]' \
    --output text)

if [ -z "$EIPS" ]; then
    echo "   No Elastic IPs"
else
    echo "$EIPS" | while read ip alloc instance; do
        printf "   %-15s | %-25s | %s\n" "$ip" "$alloc" "${instance:-unattached}"
    done
    echo ""
    read -p "   Release unattached EIPs? (y/n): " choice
    if [ "$choice" = "y" ]; then
        UNATTACHED=$(aws ec2 describe-addresses --region $REGION \
            --query 'Addresses[?InstanceId==null].AllocationId' \
            --output text)
        for alloc_id in $UNATTACHED; do
            aws ec2 release-address --region $REGION --allocation-id $alloc_id
            echo "   ✅ Released $alloc_id"
        done
    fi
fi
echo ""

# NAT Gateways
echo "🚪 NAT GATEWAYS:"
echo "----------------"
NATS=$(aws ec2 describe-nat-gateways --region $REGION \
    --query 'NatGateways[?State!=`deleted`].[NatGatewayId,State,VpcId]' \
    --output text)

if [ -z "$NATS" ]; then
    echo "   No NAT Gateways"
else
    echo "$NATS" | while read nat state vpc; do
        printf "   %-25s | %-10s | %s\n" "$nat" "$state" "$vpc"
    done
    echo ""
    read -p "   Delete all NAT Gateways? (y/n): " choice
    if [ "$choice" = "y" ]; then
        NAT_IDS=$(aws ec2 describe-nat-gateways --region $REGION \
            --query 'NatGateways[?State!=`deleted`].NatGatewayId' \
            --output text)
        for nat_id in $NAT_IDS; do
            aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $nat_id
            echo "   ✅ Deleting $nat_id"
        done
    fi
fi
echo ""

# RDS Instances
echo "🗄️  RDS INSTANCES:"
echo "------------------"
RDS=$(aws rds describe-db-instances --region $REGION \
    --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,DBInstanceStatus]' \
    --output text 2>/dev/null)

if [ -z "$RDS" ]; then
    echo "   No RDS instances"
else
    echo "$RDS" | while read id class status; do
        printf "   %-30s | %-15s | %s\n" "$id" "$class" "$status"
    done
fi
echo ""

# Load Balancers
echo "⚖️  LOAD BALANCERS:"
echo "-------------------"
LBS=$(aws elbv2 describe-load-balancers --region $REGION \
    --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' \
    --output text 2>/dev/null)

if [ -z "$LBS" ]; then
    echo "   No Load Balancers"
else
    echo "$LBS" | while read name type state; do
        printf "   %-30s | %-12s | %s\n" "$name" "$type" "$state"
    done
fi
echo ""

# DynamoDB Tables
echo "📊 DYNAMODB TABLES:"
echo "-------------------"
TABLES=$(aws dynamodb list-tables --region $REGION --query 'TableNames[*]' --output text)

if [ -z "$TABLES" ]; then
    echo "   No DynamoDB tables"
else
    for table in $TABLES; do
        echo "   $table"
    done
fi
echo ""

# Key Pairs
echo "🔑 KEY PAIRS:"
echo "-------------"
KEYS=$(aws ec2 describe-key-pairs --region $REGION --query 'KeyPairs[*].KeyName' --output text)

if [ -z "$KEYS" ]; then
    echo "   No key pairs"
else
    for key in $KEYS; do
        echo "   $key"
    done
    echo ""
    read -p "   Delete a key pair? Enter name (or 'skip'): " key_name
    if [ "$key_name" != "skip" ] && [ -n "$key_name" ]; then
        aws ec2 delete-key-pair --region $REGION --key-name $key_name
        echo "   ✅ Deleted $key_name"
    fi
fi
echo ""

echo "======================================"
echo "   Scan Complete!"
echo "======================================"
