
kubectl create namespace test01
kubectl -n test01 apply -f deploymet.yaml
kubectl -n test01 apply -f service.yaml
kubectl -n test01 apply -f ingless.yml 
kubectl get all --all-namespaces

