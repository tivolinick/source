~/login
oc project kube-system
yum install -y docker
systemctl enable docker
systemctl start docker
./secret.sh kube-system
docker login cp.icr.io --username cp --password $(cat entkey)
docker pull cp.icr.io/cp/icp-foundation/mcm-inception:3.2.8
mkdir /opt/ibm-multicloud-manager-1.3 ; cd /opt/ibm-multicloud-manager-1.3
sudo docker run --rm -v $(pwd):/data:z -e LICENSE=accept --security-opt label:disable cp.icr.io/cp/icp-foundation/mcm-inception:3.2.8 cp -r cluster /data
cd cluster
sudo ln /root/auth/kubeconfig kubeconfig

node1=$(oc get nodes | grep worker | head -1 | cut -d ' ' -f 1)
node2=$(oc get nodes | grep worker | head -2 | tail -1 |  cut -d ' ' -f 1)
node3=$(oc get nodes | grep worker | head -3 | tail -1 |  cut -d ' ' -f 1)
node4=$(oc get nodes | grep worker | head -4 | tail -1 |  cut -d ' ' -f 1)
echo $node1, $node2, $node3, $node4

sed -i "/<your-openshift-dedicated-node-to-deploy-master-components>/s//$node1/" config.yaml
sed -i "/<your-openshift-dedicated-node-to-deploy-proxy-components>/s//$node2/" config.yaml
sed -i "/<your-openshift-dedicated-node-to-deploy-management-components>/p" config.yaml
sed -i "0,/<your-openshift-dedicated-node-to-deploy-management-components>/s//$node3/" config.yaml
sed -i "/<your-openshift-dedicated-node-to-deploy-management-components>/s//$node4/" config.yaml

sc=$(oc get sc | grep block | head -1 | cut -d ' ' -f 1)
echo $sc
sed -i "s/storage_class:.*/storage_class: $sc/" config.yaml
sed -i "s/.*default_admin_password.*/default_admin_password: passw0rd/" config.yaml
sed -i -e "s/.*password_rules:.*/password_rules:/p" -e "s//  - '^([a-zA-Z0-9\-]{8,})$'/" config.yaml
sed -i '/management_services/,$d' config.yaml


echo "management_services:
# Common services
  iam-policy-controller: enabled
  metering: enabled
  licensing: disabled
  monitoring: enabled
  nginx-ingress: enabled
  common-web-ui: enabled
  catalog-ui: enabled
  mcm-kui: enabled
  logging: enabled
  audit-logging: disabled
  system-healthcheck-service: enabled
  multitenancy-enforcement: disabled

  # mcm services
  multicluster-hub: enabled
  search: enabled
  key-management: enabled
  notary: disabled
  cis-controller: disabled
  vulnerability-advisor: disabled
  mutation-advisor: disabled
  sts: disabled
image_repo: cp.icr.io/cp/icp-foundation
private_registry_enabled: true
docker_username: cp
docker_password: $(cat ~/mcm/entkey)" >> config.yaml
echo check config.yaml
echo 'hit enter when done >>>>'
read a

sudo docker run -t --net=host -e LICENSE=accept -v $(pwd):/installer/cluster:z -v /var/run:/var/run:z -v /etc/docker:/etc/docker:z --security-opt label:disable cp.icr.io/cp/icp-foundation/mcm-inception:3.2.8 install-with-openshift

