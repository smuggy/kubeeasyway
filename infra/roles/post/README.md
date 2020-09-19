# Post Kubernetes Setup
Provide some basic abilities to the cluster to allow
for monitoring and ingress. 

### Storage class
Create the storage class *ebs-sc* for to provision for
dynamic persistent volume claims.

### Dashboard
For the link to the dashboard to work
properly, the dashboard only has local access which must be proxied
to allow for access:

```console
    kubectl proxy  #(on master node defaults to port 8001)
    ssh -g -L 8001:localhost:8001 -i secrets/ez-kube-private-key.pem -f -N ubuntu@<master node ip>  (on client)
```
The dashboard will then be available at:
* http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

### Ingress

Create all necessary resources for the _nginx_ ingress controller:

* Cluster role
* Service account
* Ingress controller deployment (nginx)
* Ingress service