variable "ingressrules" {
    type = list(number)
    description = "ingress rule "
    default     = [22,80,443,3306,2049]
}

variable "egressrules" {
    type = list(number)
    description = "egress rule "
    default     = [0]
}