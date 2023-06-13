# Infrastructure

Infrastructure created using terraform to deploy a private cloud cluster to host jenkins server for apps deployment using automated pipelines.

# Setup
## Terraform
A private gke cluster of 3 nodes for higher availability and sclaibility if needed with the needed resources to provide it with secure access which are:
VPC,Subnet,Cloud NAT,Cloud NAT router,Jumphost server,IAP ssh permission.
![image](https://github.com/Gaser98/Infrastructure/assets/76227165/ee741336-0738-46df-b6c7-6e9192af0e4f)

After that,I setup IAP desktop to use the jumphost server to access my private cluster.
## Jenkins 
Jenkins server deployed with either k8s deployment files or Helm customized chart which was the preffered method as for easier installation and more stable. 

# Commands
## k8s:
kubectl create namespace 

kubectl apply -f file.yaml -n devops-tools
### For monitoring:
kubectl get pods


kubectl get deployments


kubectl get pv 


kubectl get pvc


kubectl get svc 
### For debugging:
kubectl logs [pod]


kubectl describe pod [pod] 


kubectl decribe deployment [deployment]
## Helm:
### Helm installation commands
### Customized the chart installtion using :
helm install jenkins jenkins/jenkins --set controller.serviceType=LoadBalancer --set controller.nodePort=30000 --set persistence.enabled=true
# Modules Description
### k8s
serviceAccount : to create a 'jenkins-admin' clusterRole, 'jenkins-admin' ServiceAccount and binds the 'clusterRole' to the service account


volume: to create persistent volume to keep my jenkins server files


service : to provide access to my jenkins service using thise nodeport service


deployment : to deploy jenkins server and provide a pod to host it 

### Helm:
values : displays editted values and the rest of values of the customized chart
