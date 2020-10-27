~/login
console=$(oc get routes icp-console -o=jsonpath='{.spec.host}')
port=$(oc get configmap ibmcloud-cluster-info -n kube-public -o=jsonpath='{.data.cluster_router_https_port}')
proxy=$(oc get configmap ibmcloud-cluster-info -n kube-public -o=jsonpath='{.data.proxy_address}')
echo "Cloud Console FQDN: $console"
echo "Cloud Console Port: $port"
echo "Cloud Proxy FQDN: $proxy"
