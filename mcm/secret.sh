#!/bin/sh
userpart="--docker-username=cp"
passpart="--docker-password=eyJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJJQk0gTWFya2V0cGxhY2UiLCJpYXQiOjE1ODg2ODU1MzYsImp0aSI6ImQ5NTExYTUwM2Y0ODRlYzY4NWFhOTE2MjE0MTJjMGYyIn0.AmpHkGTzQEfjYblf_rDFf99fZb5gBdg5r6i8CbOMocQ"
servpart="--docker-server=cp.icr.io"
if [ $# -eq 0 ] ; then
  oc create secret docker-registry ibm-entitlement-key $userpart $passpart $servpart
  exit 0
fi
for ns in $* ; do
  echo $ns
  oc create secret docker-registry ibm-entitlement-key -n $ns $userpart $passpart $servpart
done

