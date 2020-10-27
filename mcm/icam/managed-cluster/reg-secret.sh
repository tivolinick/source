my_registry_name=$(oc get route default-route -n openshift-image-registry --no-headers | awk '{print $2}')
kubectl create secret docker-registry my-registrykey --docker-server=$my_registry_name --docker-username=kubeadmin --docker-password=$(oc whoami -t) -n multicluster-endpoint

