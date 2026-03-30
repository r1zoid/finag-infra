environment = "dev"
# service_account_id = "replace-with-service-account-id"
image_id = "fd86k5lln2u2bvfuk00u"

backend_enable_coi_runtime = false

backend_min_size   = 1
backend_max_size   = 2
backend_cpu_target = 70
backend_cores      = 2
backend_memory     = 4

pg_resource_preset = "s2.micro"
pg_disk_size       = 20

kafka_broker_count = 1
kafka_disk_size    = 50
