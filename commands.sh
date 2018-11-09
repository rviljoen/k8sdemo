# Install supporting tools
brew install bash # Upgrade to latest version which supports better completion
brew install bash-completion

# Add to ~/.bash_profile
if [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# Add autocompletion for k8s specific commands
source <(kubectl completion bash)

brew install jq
brew install watch

# ------------------------

# Select the relevant k8s config
export KUBECONFIG=~/.kube/config


# Looking at the cluster
kubectl get nodes
kubectl get pods --namespace=kube-system
kubectl get all

# Running a single pod (i.e. no deployment)
kubectl run --generator=run-pod/v1 --image=gcr.io/kuar-demo/kuard-amd64:1 kuard
kubectl get pods
kubectl run --generator=run-pod/v1 --image=gcr.io/kuar-demo/kuard-amd64:1 kuard --dry-run -o yaml
kubectl get pods kuard -o yaml
kubectl port-forward kuard 8080:8080
kubectl delete pod kuard

# Running a deployment
kubectl run --image=gcr.io/kuar-demo/kuard-amd64:1 kuard --replicas=5 --dry-run -o yaml
kubectl run --image=gcr.io/kuar-demo/kuard-amd64:1 kuard --replicas=5
kubectl get pods

# Running a service
kubectl expose deployment kuard --type=LoadBalancer --port=80 --target-port=8080 --dry-run -o yaml
kubectl expose deployment kuard --type=LoadBalancer --port=80 --target-port=8080
kubectl get service kuard -o wide

# -----------------------

# Doing a deployment

# Window 1
watch -n 1 kubectl get pods

# Window 2
while true ; do curl -s 40.115.109.9/env/api | jq '.env.HOSTNAME'; done

# Window 3
kubectl scale deployment kuard --replicas=10
kubectl set image deployment kuard kuard=gcr.io/kuar-demo/kuard-amd64:2
kubectl rollout undo deployment kuard

# -----------------------

# Cleanup
kubectl delete deployment kuard
kubectl delete services kuard


# -----------------------

# Demo WordPress install with Helm

# Install Helm client (assumes cluster already has Helm Tiller installed)
brew install kubernetes-helm
helm init --client-only

# Window 1
kubectl create namespace ruan-wp-demo
watch -n 1 kubectl get all,pv,pvc --namespace=ruan-wp-demo -o wide

# Window 2
helm install --namespace=ruan-wp-demo --name wordpress stable/wordpress

kubectl get svc --namespace ruan-wp-demo wordpress-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
kubectl get secret --namespace ruan-wp-demo wordpress-wordpress -o jsonpath='{.data.wordpress-password}' | base64 --decode

# Access the website on ingress IP (Note: On Azure this may take 5 to 10 mins to appear on the public Internet)

# Cleanup
kubectl delete ns ruan-wp-demo