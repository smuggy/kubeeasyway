# Kubernetes the Easy Way

This project will create a simple Kubernetes cluster. The resource
folder holds the Terraform modules which can be used
to build the AWS resources necessary for the cluster. The
infra folder holds the Ansible code to stand up the cluster
using _kubeadm_.

## Assumptions

The VPCs are already setup and available for use. This requires
running the Terraform scripts in the [VPCs](https://github.com/smuggy/vpcs) repository first.

## Commands to remember for use
These are not necessary now, the dashboard is available
at the https://kubernetes.podspace.net/dashboard
podspace.net is a domain owned by me, so please do not
use, replace that.

Run this in the kubernetes master node:
```shell script
kubectl proxy
```

Run this on the node connecting to the master node:
```shell script
ssh -g -L 8001:localhost:8001 -f -N cloud_user@<Your master server IP address here>
```

Go to this site:
```http request
http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```
to access the dashboard.

or update the service yaml to use a nodeport and access without path.
kubectl -n kubernetes-dashboard edit service kubernetes-dashboard

https://kubernetes.podspace.net:xxxxx/
