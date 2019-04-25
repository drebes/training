#!/bin/bash

export TF_WARN_OUTPUT_ERRORS=1

export GOOGLE_PROJECT=$(gcloud config get-value project)
echo "GOOGLE_PROJECT variable set as active project [$GOOGLE_PROJECT] "
echo ""

export TF_VAR_project_id=$(gcloud config get-value project)
echo "TF_VAR_project_id variable set as active project [$TF_VAR_project_id] "
echo ""

while getopts d:h: option
do
  case "${option}" in
    d) FOLDER=$OPTARG;;
    h) HELP=$OPTARG;;
esac
done

tf_apply() {
  cd $FOLDER
  echo "Running 'terraform init'..."
  echo ""
  terraform init -input=false

  echo "Running 'terraform plan'..."
  echo ""
  terraform plan -input=false -out tfplan -var project_id=$project_id

  echo "Running 'terraform apply'..."
  echo ""
  terraform apply -input=false tfplan

  if [ -f tfplan ]; then
    rm tfplan
  fi
}

#tf_apply
