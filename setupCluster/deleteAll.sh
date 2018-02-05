kubectl delete pods $(kubectl get pod -n org1-v1 | awk 'NR>1{print $1}') -n org1-v1 --grace-period=0 --force
kubectl delete pods $(kubectl get pod -n org2-v1 | awk 'NR>1{print $1}') -n org2-v1 --grace-period=0 --force
kubectl delete pods $(kubectl get pod -n orgorderer-v1 | awk 'NR>1{print $1}') -n orgorderer-v1 --grace-period=0 --force
kubectl delete namespaces --now org1-v1 --force
kubectl delete namespaces --now org2-v1 --force
kubectl delete namespaces --now channel --force
kubectl delete namespaces --now orgorderer-v1 --force
