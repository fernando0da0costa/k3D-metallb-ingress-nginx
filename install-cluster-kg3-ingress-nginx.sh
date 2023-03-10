#https://medium.com/linux-shots/spin-up-a-lightweight-kubernetes-cluster-on-linux-with-k3s-metallb-and-nginx-ingress-167d98f3583d

export name_cluster="t0111"
#sudo iptables -I FORWARD -j ACCEPT

function uninstall_k3D(){
k3d cluster delete $name_cluster
}

function install_k3D(){
k3d cluster create $name_cluster --api-port 6550 --agents 2 --k3s-arg "--disable=traefik@server:0" --k3s-arg "--disable=servicelb@server:0" --no-lb --wait --image rancher/k3s:v1.26.2-rc1-k3s1
}

function install_ingles_metallb(){
#sudo apt install jq -y

kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

export  cidr_block=$(docker network inspect  k3d-$name_cluster | jq '.[0].IPAM.Config[0].Subnet' | tr -d '"')
export  base_addr=${cidr_block%???}
export  first_addr=$(echo $base_addr | awk -F'.' '{print $1,$2,$3,240}' OFS='.')
export  range=$first_addr/29

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


kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.1.1/deploy/static/provider/cloud/deploy.yaml
kubectl -n ingress-nginx get svc ingress-nginx-controller


}




function install_teste01(){
cd ex01
chmod +x start.sh
./start.sh
sed '/hello.local/d' /etc/hosts #Apaga as linhas que contem a palavra vivaolinux
echo "$first_addr hello.local" >> /etc/hosts
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "open http://hello.local" 
sleep 20
open http://hello.local
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo $range
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
#kubectl get all --all-namespaces
}

function install_argo(){
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.4.5/install.yaml
kubectl patch deployment \
  argo-server \
  --namespace argo \
  --type='json' \
  -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/args", "value": [
  "server",
  "--auth-mode=server"
]}]'
}

uninstall_k3D
install_k3D
install_ingles_metallb
kubectl get all --all-namespaces
echo esperando servico subrir
sleep 200
install_teste01
#install_argo
