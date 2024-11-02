vterraform {
  required_providers {
    vcd = {
      source  = "vmware/vcd"
      version = "3.14"
    }
  }
}

provider "vcd" {
  user                     = var.vcd_user                # Your VCD username
  password                 = var.vcd_password            # Your VCD password
  org                      = "org_name"                   # Your organization name
  vdc                      = "vdc_name"        # Your VDC name
  url                      = "https://your-api-endpoint" # VCD API endpoint
  allow_unverified_ssl     = true                        # Set to false for production
}

variable "vcd_user" {}
variable "vcd_password" {}

resource "vcd_network_routed" "net" {
  org           = "org_name"                          # Your organization name
  vdc           = "vdc_name"               # Your VDC name
  name          = "network_name"                          # Network name
  edge_gateway  = "edge_name"                   # Edge gateway name
  gateway       = "x.x.x.1"                     # Gateway IP
  dns1          = "dns ip"                           # Primary DNS

  static_ip_pool {
    start_address = "x.x.x.2"                # Start of static IP pool
    end_address   = "x.x.x.254"                # End of static IP pool
  }
}

resource "vcd_vapp" "web" {
  name = "web"                                      # VApp name
}

resource "vcd_vapp_org_network" "direct-network" {
  vapp_name        = vcd_vapp.web.name
  org_network_name = vcd_network_routed.net.name
}

data "vcd_catalog" "my-catalog" {
  org  = "org_name"                                  # Your organization name
  name = "Gataolg_name"                                     # Catalog name
}

data "vcd_catalog_vapp_template" "photon-os" {
  org        = "org_name"                            # Your organization name
  catalog_id = data.vcd_catalog.my-catalog.id
  name       = "Tempalte_name"           # Template name
}

resource "vcd_vapp_vm" "web1" {
  vapp_name         = vcd_vapp.web.name
  name              = "web1"                         # VM name
  vapp_template_id  = data.vcd_catalog_vapp_template.photon-os.id
  memory            = 4096                            # VM memory in MB
  cpus              = 4                               # Number of CPUs

  network {
    type               = "org"
    name               = vcd_vapp_org_network.direct-network.org_network_name
    ip_allocation_mode = "POOL"
  }

  user_data = <<EOF
#!/bin/bash
# Commands to run at startup
yum update -y
EOF

  ssh_keys = ["ssh-rsa AAAAB3NzaC..."]               # Your actual SSH public key

  tags = ["environment:production", "project:my_project"] # Tags for resource management
}

resource "vcd_vapp_vm" "web2" {
  vapp_name         = vcd_vapp.web.name
  name              = "web2"                         # VM name
  vapp_template_id  = data.vcd_catalog_vapp_template.photon-os.id
  memory            = 4096                            # VM memory in MB
  cpus              = 4                               # Number of CPUs

  network {
    type               = "org"
    name               = vcd_vapp_org_network.direct-network.org_network_name
    ip_allocation_mode = "POOL"
  }

  user_data = <<EOF
#!/bin/bash
# Commands to run at startup
yum update -y
EOF

  ssh_keys = ["ssh-rsa AAAAB3NzaC..."]               # Your actual SSH public key

  tags = ["environment:production", "project:my_project"] # Tags for resource management
}

data "vcd_nsxt_edgegateway" "testing" {
  name = "edge_name"                             # Edge gateway name
  org  = "org_name"                                   # Your organization name
}

resource "vcd_nsxt_firewall" "ansible-tier01" {
  org = "org_name"                                   # Your organization name
  edge_gateway_id = data.vcd_nsxt_edgegateway.testing.id

  rule {
    action      = "ALLOW"
    name        = "allow all IPv4 traffic"
    direction   = "IN_OUT"
    ip_protocol = "IPV4"
  }
}

resource "vcd_nsxt_nat_rule" "snat" {
  org = "org_name"                                   # Your organization name
  edge_gateway_id = data.vcd_nsxt_edgegateway.testing.id

  name        = "Terraform_SNAT rule"
  rule_type   = "SNAT"
  description = "description"

  external_address         = "public ip"      # External IP address
  internal_address         = "praiavte ip"      # Internal network
  snat_destination_address = "dns ip "                # SNAT destination address
  logging                  = true                      # Enable logging
}

# Outputs for important values
output "web1_ip" {
  value = vcd_vapp_vm.web1.ip                      # Output for web1 IP
}

output "web2_ip" {
  value = vcd_vapp_vm.web2.ip                      # Output for web2 IP
}
