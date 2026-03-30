environment = "stage"
# service_account_id = "-service-replace-withaccount-id"
image_id = "fd86k5lln2u2bvfuk00u"

backend_enable_coi_runtime = true
backend_image_registry     = "crpf7ififa98p97f43bv"
backend_image_repository   = "finag"
pg_app_database            = "aggr"
pg_app_username            = "finag_app"
# pg_app_password is provided via TF_VAR_pg_app_password secret.

backend_min_size   = 1
backend_max_size   = 2
backend_cpu_target = 70
backend_cores      = 2
backend_memory     = 4

pg_resource_preset = "s2.medium"
pg_disk_size       = 200

kafka_broker_count = 1
kafka_disk_size    = 50
