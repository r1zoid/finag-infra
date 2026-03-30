environment = "prod"
# service_account_id = "replace-with-service-account-id"
image_id = "fd86k5lln2u2bvfuk00u"

backend_enable_coi_runtime = true
backend_image_registry     = "crpf7ififa98p97f43bv"
backend_image_repository   = "finag"
pg_app_database            = "aggr"
pg_app_username            = "finag_app"
# pg_app_password is provided via TF_VAR_pg_app_password secret.

backend_min_size   = 2
backend_max_size   = 4
backend_cpu_target = 70
backend_cores      = 4
backend_memory     = 8

pg_resource_preset = "s2.small"
pg_disk_size       = 200

kafka_broker_count = 3
kafka_disk_size    = 50
