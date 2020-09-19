#!/usr/bin/env bash
region="$1"
vpc="$2"
zone="$3"
v=$(aws route53 list-hosted-zones-by-vpc --region "${region}" --vpc-region "${region}" --vpc-id "${vpc}" --output text --query 'HostedZoneSummaries[].[HostedZoneId,Name]' | grep "${zone}")
nv="${v%%	*}"
echo "{\"value\":\"${nv}\"}"
exit 0
