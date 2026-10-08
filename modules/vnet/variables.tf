variable "name"            { type = string }
variable "location"        { type = string }
variable "address_space"   { type = list(string) }
variable "subnet_prefixes" { type = list(string) }
variable "subnet_names"    { type = list(string) }
variable "tags" { type = map(string), default = {} }
