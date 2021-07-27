variable "debian_nodes" {
  description = "List of nodes to provision with debian cloud image"
  type	= list(string)
  default = ["debian1"]
}

variable "rhel_nodes" {
  description = "List of nodes to provision with rhel cloud image"
  type  = list(string)
  default = ["rhel1"]
}
