terraform {
  required_version = ">= 1.1.6"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "> 0.90.0"
    }
  }
}
provider "yandex" {
  service_account_key_file = file("/home/akha/key.json")
  cloud_id                 = "b1g5fjugjkch6hcqqnok"
  folder_id                = "b1gnh3c0khmhhi97erbd"
  zone                     = "ru-central1-a"
}
