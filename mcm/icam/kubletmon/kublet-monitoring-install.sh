~/login
oc project kube-system
#oc patch serviceaccount default -p '{"imagePullSecrets": [{"name": "ibm-entitlement-key"}]}' -n kube-system
#oc describe serviceaccount default -n kube-system
tar xf agent_ppa_2020.1.0_prod_amd64.tar.gz images/
yum install -y docker
systemctl enable docker
systemctl start docker
oc patch configs.imageregistry.operator.openshift.io/cluster --patch '{"spec":{"defaultRoute":true}}' --type=merge
my_registry_name=$(oc get routes -n openshift-image-registry | grep default-route | awk '{ print $2 }')
echo $my_registry_name
echo "{
   \"ipv6\": false,
   \"insecure-registries\": [\"$my_registry_name\"]
 }" > /etc/docker/daemon.json
systemctl restart docker

~/login
docker login $my_registry_name -u kubeadmin -p $(oc whoami -t)
#from manual
docker load -i images/agentoperator_APM_202003100816.tar.gz
docker tag agentoperator:APM_202003100816 $my_registry_name/multicluster-endpoint/agentoperator:APM_202003100816  
docker push $my_registry_name/multicluster-endpoint/agentoperator:APM_202003100816
docker load -i images/k8-monitor_APM_202003092352.tar.gz
docker tag k8-monitor:APM_202003092352 $my_registry_name/multicluster-endpoint/k8-monitor:APM_202003092352  
docker push $my_registry_name/multicluster-endpoint/k8-monitor:APM_202003092352
docker load -i images/k8sdc-operator_APM_202003092352.tar.gz
docker tag k8sdc-operator:APM_202003092352 $my_registry_name/multicluster-endpoint/k8sdc-operator:APM_202003092352  
docker push $my_registry_name/multicluster-endpoint/k8sdc-operator:APM_202003092352
docker load -i images/reloader_202002170811-multi-arch.tar.gz
docker tag reloader:202002170811-multi-arch $my_registry_name/multicluster-endpoint/reloader:202002170811-multi-arch  
docker push $my_registry_name/multicluster-endpoint/reloader:202002170811-multi-arch

~/login
kubectl create secret docker-registry my-registrykey --docker-server=$my_registry_name --docker-username=kubeadmin --docker-password=$(oc whoami -t) -n multicluster-endpoint

kubectl apply -f - <<@
apiVersion: v1
kind: ServiceAccount
metadata:
  name: icamklust
  namespace: multicluster-endpoint
@
kubectl patch serviceaccount icamklust -p '{"imagePullSecrets": [{"name": "my-registrykey"}]}' -n multicluster-endpoint

oc create clusterrolebinding icam-cluster-role-binding --clusterrole=cluster-admin --serviceaccount=multicluster-endpoint:icamklust -n multicluster-endpoint
oc create clusterrolebinding icam-cluster-role-binding-default --clusterrole=cluster-admin --serviceaccount=multicluster-endpoint:default -n multicluster-endpoint

registry_name=$(oc registry info --internal)
echo $registry_name
kubectl apply -f - <<@
 apiVersion: apiextensions.k8s.io/v1beta1
 kind: CustomResourceDefinition
 metadata:
   name: k8sdcs.ibmcloudappmgmt.com
 spec:
   group: ibmcloudappmgmt.com
   names:
     kind: K8sDC
     listKind: K8sDCList
     plural: k8sdcs
     singular: k8sdc
   scope: Namespaced
   subresources:
     status: {}
   version: v1alpha1
   versions:
   - name: v1alpha1
     served: true
     storage: true
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: k8sdc-operator
 namespace: multicluster-endpoint
spec:
 replicas: 1
 selector:
   matchLabels:
     name: k8sdc-operator
 template:
   metadata:
     labels:
       name: k8sdc-operator
   spec:
     serviceAccountName: icamklust
     containers:
       - name: k8sdc-operator
         # Replace this with the built image name
         image: $registry_name/multicluster-endpoint/k8sdc-operator:APM_202003092352
         imagePullPolicy: Always
         env:
           - name: WATCH_NAMESPACE
             valueFrom:
               fieldRef:
                 fieldPath: metadata.namespace
           - name: POD_NAME
             valueFrom:
               fieldRef:
                 fieldPath: metadata.name
           - name: OPERATOR_NAME
             value: "k8sdc-operator"
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: icam-reloader
 namespace: multicluster-endpoint
spec:
 replicas: 1
 revisionHistoryLimit: 2
 selector:
   matchLabels:
     name: icam-reloader
 template:
   metadata:
     labels:
       name: icam-reloader
   spec:
     securityContext:
       runAsNonRoot: true
       runAsUser: 1000
     containers:
     - env:
       - name: KUBERNETES_NAMESPACE
         valueFrom:
           fieldRef:
             apiVersion: v1
             fieldPath: metadata.namespace
       # Replace this with the built image name
       image: $registry_name/multicluster-endpoint/reloader:202002170811-multi-arch
       resources:
         limits:
           cpu: "500m"
           memory: "100Mi"
         requests:
           cpu: "50m"
           memory: "50Mi"
       imagePullPolicy: Always
       name: icam-reloader
---
apiVersion: apps/v1
kind: Deployment
metadata:
 name: agentoperator
 namespace: multicluster-endpoint
spec:
 replicas: 1
 selector:
   matchLabels:
     name: agentoperator
 template:
   metadata:
     labels:
       name: agentoperator
   spec:
     serviceAccountName: icamklust
     containers:
       - name: agentoperator
         # Replace this with the built image name
         image: $registry_name/multicluster-endpoint/agentoperator:APM_202003100816
         imagePullPolicy: Always
         command:
         - agentoperator
         args:
         - "--image-repo=$registry_name/multicluster-endpoint"
         - "--image-prefix="
         env:
           - name: POD_NAME
             valueFrom:
               fieldRef:
                 fieldPath: metadata.name
           - name: OPERATOR_NAME
             value: "agentoperator"
         volumeMounts:
         - name: klusterlet-config
           mountPath: /opt/klusterlet
     volumes:
       - name: klusterlet-config
         secret:
           secretName: endpoint-connmgr-hub-kubeconfig
@

kubectl get deployment k8sdc-operator --namespace=multicluster-endpoint
kubectl get deployment icam-reloader --namespace=multicluster-endpoint
kubectl get deployment agentoperator --namespace=multicluster-endpoint
#kubectl get deployment k8sdc-cr-k8monitor --namespace=multicluster-endpoint
