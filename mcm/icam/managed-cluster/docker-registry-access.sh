oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
route=$(oc get route default-route -n openshift-image-registry --no-headers | awk '{print $2}')
echo $route
echo "{
    \"insecure-registries\" : [\"$route\"]
}" > /etc/docker/daemon.json

sudo systemctl restart docker
~                                                                                                                                                                                               

