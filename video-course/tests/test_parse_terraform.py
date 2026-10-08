"""Terraform parser — hcl2 path, dependency edges, reduced-confidence fallback."""
import parse_terraform as pt

MAIN_TF = '''
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "tags" {
  type = map(string)
}

locals {
  common_tags = merge(var.tags, { managed = "terraform" })
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-lab"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_storage_account" "sa" {
  name                     = "salab01"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

data "azurerm_client_config" "current" {}

output "sa_id" {
  value = azurerm_storage_account.sa.id
}
'''


def write_lab(tmp_path):
    (tmp_path / "main.tf").write_text(MAIN_TF, encoding="utf-8")
    return sorted(str(tmp_path / "main.tf").split()) and [str(tmp_path / "main.tf")]


def test_hcl2_full_parse(tmp_path):
    inv = pt.parse_with_hcl2(write_lab(tmp_path))
    names = [r["address"] for r in inv["resources"]]
    assert "azurerm_resource_group.rg" in names
    assert "azurerm_storage_account.sa" in names
    assert inv["data_sources"] and "data.azurerm_client_config.current" in \
        [d["address"] for d in inv["data_sources"]]
    assert any(v["name"] == "location" for v in inv["variables"])
    assert any(l["name"] == "common_tags" for l in inv["locals"])
    assert any(o["name"] == "sa_id" for o in inv["outputs"])
    assert any(rp.get("name") == "azurerm" and rp.get("source") == "hashicorp/azurerm"
               for rp in inv["required_providers"])


def test_dependency_edges_resolved(tmp_path):
    inv = pt.parse_with_hcl2(write_lab(tmp_path))
    edges = inv["dependency_edges"]
    pairs = {(e["from"], e["to"]) for e in edges}
    # sa depends on rg (resource->resource) and on local.common_tags
    assert ("resource:azurerm_storage_account.sa", "resource:azurerm_resource_group.rg") in pairs
    assert ("resource:azurerm_resource_group.rg", "variable:location") in pairs
    assert any(t == "local:common_tags" for _, t in pairs)


def test_no_self_edges(tmp_path):
    inv = pt.parse_with_hcl2(write_lab(tmp_path))
    for e in inv["dependency_edges"]:
        assert e["from"] != e["to"]


def test_regex_fallback_reduced_confidence(tmp_path):
    inv = pt.parse_with_regex(write_lab(tmp_path))
    assert inv["dependency_edges"] == []  # fallback never fabricates edges
    assert inv["resources"]  # resources still listed