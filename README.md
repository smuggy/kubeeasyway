
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
