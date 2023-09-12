variable "region1" {
    type = "string"
    default = "us-east-1"
}
variable "id_image" {
    type = string
    default = "ami-0261755bbcb8c4a84"
}
variable "id_vpc" {
    type = string
    default = "vpc-0dee5d356fa292024"
}
variable "id_subnet" {
    type = string
    default ="subnet-0a799f29f38d852a5"
}
variable "key_access" {
    type = "string"
}
variable "key_secret" {
    type = "string"
}
variable "instance_type" {
    type = "string"
    default = "t2.medium"
}


### variables for traffic