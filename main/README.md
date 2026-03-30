# Terraform for financial aggregator

## Quick start

1. Fill non-secret placeholders in `dev.tfvars`, `stage.tfvars`, or `prod.tfvars`.
2. Provide sensitive values securely (do not commit):
   - `export TF_VAR_kafka_producer_password='...'`
   - `export TF_VAR_kafka_worker_password='...'`
   - `export TF_VAR_pg_app_password='...'`
   - `export TF_VAR_service_account_id='...'`
   - `export TF_VAR_ssh_public_key='ssh-ed25519 AAAA... user@host'`
3. Run:
   - `terraform init`
   - `terraform plan -var-file=dev.tfvars`

## Notes

- `prod` enforces at least 3 Kafka brokers.
- Managed PostgreSQL and Kafka are deployed as multi-zone in `prod`.
- Backend instance group registers targets for ALB automatically.
- For `stage`/`prod`, backend containers are configured to run on MIG instances via VM metadata `docker-compose`.
- COI VM in CI is kept only for test deployments.
- You can override rollout image tag at deploy time with `-var "backend_image_tag=<tag>"`.
