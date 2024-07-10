variable "key_name" {
  type    = string
  default = "mac"
}

variable "google_db_password" {
  description = "Password for the Google DB"
  type        = string
  sensitive   = true
}

variable "google_db_name" {
  description = "Name of the Google DB"
  type        = string
  default     = "google"
}

variable "google_db_user" {
  description = "User for the Google DB"
  type        = string
  default     = "googleuser"
}

variable "metabase_password" {
  description = "Password for the Metabase user"
  type        = string
  sensitive   = true
}
variable "metabase_mail" {
  description = "Mail for the Metabase user"
  type        = string
  sensitive   = true
}