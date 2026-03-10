# Terraform for financial aggregator

## Quick start

1. Fill non-secret placeholders in `dev.tfvars`, `stage.tfvars`, or `prod.tfvars`.
2. Provide Kafka passwords securely (do not commit):
   - `export TF_VAR_kafka_producer_password='...'`
   - `export TF_VAR_kafka_worker_password='...'`
3. Run:
   - `terraform init`
   - `terraform plan -var-file=dev.tfvars`

## Notes

- `prod` enforces at least 3 Kafka brokers.
- Managed PostgreSQL and Kafka are deployed as multi-zone in `prod`.
- Backend instance group registers targets for ALB automatically.
