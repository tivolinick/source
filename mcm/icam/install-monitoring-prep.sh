~/login
oc project kube-system
oc patch serviceaccount default -p '{"imagePullSecrets": [{"name": "ibm-entitlement-key"}]}' -n kube-system
oc describe serviceaccount default -n kube-system
 oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
oc get routes -n openshift-image-registry | grep default-route | awk '{ print $2 }'

echo '{
   "ipv6": false,
   "insecure-registries": ["your_default_route_here"]
 }' > /etc/docker/daemon.json
systemctl restart docker

oc get route -n kube-system
oc get sc | grep block
echo ibm-entitlement-key

echo 'sync helm repositories'
echo 'Catalog'
echo 'Repositories -> ibm-entitled-charts'
echo 'ibm-cloud-appmgmt-prod'
echo
echo 'icam, kube-system, local-cluster'


