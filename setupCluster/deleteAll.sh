kubectl delete pods $(kubectl get pod -n org1-f-1 | awk 'NR>1{print $1}') -n org1-f-1 --grace-period=0 --force
kubectl delete pods $(kubectl get pod -n org2-f-1 | awk 'NR>1{print $1}') -n org2-f-1 --grace-period=0 --force
kubectl delete pods $(kubectl get pod -n orgorderer-f-1 | awk 'NR>1{print $1}') -n orgorderer-f-1 --grace-period=0 --force
kubectl delete namespaces --now org1-f-1 --force
kubectl delete namespaces --now org2-f-1 --force
kubectl delete namespaces --now channel --force
kubectl delete namespaces --now orgorderer-f-1 --force
