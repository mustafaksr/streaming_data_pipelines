
variable "gcp_project_id" {
  description = "Google Cloud Project ID"
    
}
variable "region" {
  description = "Google Cloud Project Region"
  default = "us-east1"
}
variable "zone" {
  description = "Google Cloud Project Zone"
  default = "us-east1-a"
}


variable "mongodb_username" {
  type = string
  description = "This variable is used to specify the username for the MongoDB database."
  default = "dbuser"
    
}

variable "mongodb_password" {
  type = string
  description = "This variable is used to specify the password for the MongoDB database"
  default = "atlas"
    
}
variable "mongodb_public_key" {
  type = string
  description = "This variable is used to specify the MongoDB public key for the SSH key pair used to connect to instances"

  sensitive = true 
}
variable "mongodb_private_key" {
  type = string
  description = "This variable is used to specify the MongoDB private key for the SSH key pair used to connect to instances."
  sensitive = true
}

variable "atlas_project_name" {
  description = "Atlas Project Name"
  
}
variable "atlas_org_id" {
  description = "Atlas Organization ID for creating Atlas Project"
  sensitive = true
}
