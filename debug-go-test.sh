#!/bin/bash

cp deploy/service_account.yaml deploy/namespace-init.yaml
echo -e "\n---\n" >> deploy/namespace-init.yaml
cat deploy/role.yaml >> deploy/namespace-init.yaml
echo -e "\n---\n" >> deploy/namespace-init.yaml
cat deploy/role_binding.yaml >> deploy/namespace-init.yaml
# echo -e "\n---\n" >> deploy/namespace-init.yaml
# cat deploy/operator.yaml >> deploy/namespace-init.yaml

cp deploy/crds/operator.ibm.com_operandconfigs_crd.yaml deploy/crds-init.yaml
echo -e "\n---\n" >> deploy/crds-init.yaml
cat deploy/crds/operator.ibm.com_operandregistries_crd.yaml >> deploy/crds-init.yaml
echo -e "\n---\n" >> deploy/crds-init.yaml
cat deploy/crds/operator.ibm.com_operandrequests_crd.yaml >>  deploy/crds-init.yaml
echo -e "\n---\n" >> deploy/crds-init.yaml
cat deploy/crds/operator.ibm.com_operandbindinfos_crd.yaml >>  deploy/crds-init.yaml
