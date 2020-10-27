echo Installing the service catalog
echo
echo 'oc edit servicecatalogapiservers

Under spec, set the managementState field to Managed:

spec:
  logLevel: Normal
  managementState: Managed

HIT ENTER TO CONTIUE >>>>>'
read a

echo  oc get pods -n openshift-service-catalog-apiserver
echo 'HIT ENTER TO CONTIUE >>>>>'
read a


echo 'oc edit servicecatalogcontrollermanagers

Under spec, set the managementState field to Managed:

spec:
  logLevel: Normal
  managementState: Managed

HIT ENTER TO CONTIUE >>>>>'
read a

echo  oc get pods -n openshift-service-catalog-controller-manager
echo 'HIT ENTER TO CONTIUE >>>>>'
read a

cp ../clis/helm /usr/bin/
helm init
cp ../clis/cloudctl /usr/bin/
cloudctl plugin install ../clis/cloudctl-mc-plugin
helm repo add ibm-stable https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
helm repo update

../secret.sh services
oc adm policy add-scc-to-group privileged system:serviceaccounts:services
export serviceIDName='service-deploy'
export serviceApiKeyName='service-deploy-api-key'
route=$(oc get route icp-console -n kube-system -o jsonpath='{.spec.host}')

cloudctl login -a https://$route --skip-ssl-validation -u admin -p passw0rd -n services
cloudctl iam service-id-create ${serviceIDName} -d 'Service ID for service-deploy'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'idmgmt'
cloudctl iam service-policy-create ${serviceIDName} -r Administrator,ClusterAdministrator --service-name 'identity'
api=$(cloudctl iam service-api-key-create ${serviceApiKeyName} ${serviceIDName} -d 'Api key for service-deploy' | tail -1 | awk '{print $3}')
echo API key: $api
helm fetch ibm-stable/ibm-cam --version 4.2.1


echo 'Here we go. HIT ENTER TO CONTIUE >>>>>'
read a
helm install -f overwritten.yaml  ibm-cam-4.2.1.tgz --name cam --namespace services --set global.image.secretName=ibm-entitlement-key --set image.repository=cp.icr.io/cp/ --set icp.port=443 --set global.iam.deployApiKey=${api} --tls 

