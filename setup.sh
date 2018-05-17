#!/usr/bin/env bash
virtualenv venv -p python3
source venv/bin/activate
pip install -r requirements.txt
TF_PLUGINS="${HOME}/.terraform.d/plugins"
TF_DOCK_PROV="terraform-provider-docker-image"
if [ ! -d "${TF_PLUGINS}" ]
then
  mkdir -p ${TF_PLUGINS}
fi
if [ ! -f "${TF_PLUGINS}/terraform-provider-docker-image" ]
then
  echo "No terraform-provider-docker-image found!"
  cwd=${PWD}
  cd ${TF_PLUGINS}
  go get github.com/diosmosis/terraform-provider-docker-image
  go build github.com/diosmosis/terraform-provider-docker-image
  cat <<- EOF > ~/.terraformrc
providers {
  dockerimage = "${TF_PLUGINS}/terraform-provider-docker-image"
}
EOF
  cd ${cwd}
fi
