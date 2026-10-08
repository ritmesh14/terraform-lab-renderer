# tfvars supplies the map. Change which tiers get NSGs by flipping nsg here.
subnets = {
  web  = { prefix = "10.170.1.0/24", nsg = true }
  app  = { prefix = "10.170.2.0/24", nsg = true }
  data = { prefix = "10.170.3.0/24", nsg = false }
}
