data azurerm_subnet subnet_1 {
  resource_group_name  = "sandbox-network-rg"
  virtual_network_name = "scratch-central-us"
  name                 = "scratch-subnet-1"
}

data azurerm_network_security_group vn_group {
  name                = "sandbox_net_sg"
  resource_group_name = "sandbox-network-rg"
}

data azurerm_shared_image_version ubuntu {
  gallery_name        = "ImageGallery"
  image_name          = "UbuntuLinux"
  resource_group_name = "sandbox-network-rg"
  name                = "2.0.0"
}
