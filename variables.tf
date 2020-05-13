variable "volume_dev" {
  type        = string
  description = "Path of the attached volumes device file."
}

variable "root_dev" {
  type        = string
  description = "Path of the root device file."
}

variable "context" {
  type        = string
  description = "Build context of the install container to use."
}

variable "user" {
  type        = string
  description = "Primary user of the cloudd VM."
  default     = ""
}

variable "password" {
  type        = string
  description = "Password of the primary user in plaintext."
  default     = ""
}

variable "ssh_key" {
  type        = string
  description = "SSH public key added to primary users authorized_keys."
  default     = ""
}
