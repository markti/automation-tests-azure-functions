terraform init

#export TF_LOG=ERROR
export ARM_SUBSCRIPTION_ID=foo

terraform test -verbose
