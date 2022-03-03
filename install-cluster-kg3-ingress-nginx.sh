#https://medium.com/linux-shots/spin-up-a-lightweight-kubernetes-cluster-on-linux-with-k3s-metallb-and-nginx-ingress-167d98f3583d

name_cluster="t01"
#sudo iptables -I FORWARD -j ACCEPT
k3d cluster delete $name_cluster

k3d cluster create $name_cluster --api-port 6550 --agents 2 --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait

#sudo apt install jq -y

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

cidr_block=$(docker network inspect  k3d-$name_cluster | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
base_addr=${cidr_block%???}
first_addr=$(echo $base_addr | awk -F'.' '{print $1,$2,$3,240}' OFS='.')
range=$first_addr/29

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - $range
EOF

#kubectl create deploy nginx --image=nginx
#kubectl expose deploy nginx --port=80 --target-port=80 --type=LoadBalancer
#kubectl get svc nginx
#kubectl delete deploy nginx
#kubectl delete svc nginx

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/aws/deploy.yaml
kubectl -n ingress-nginx get svc ingress-nginx-controller

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo $range
echo "$first_addr hello.local" >> /etc/hosts
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
kubectl get all --all-namespaces
cd /ex01
chmod +x start.sh
./start.sh

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo " open http://hello.local" 
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"