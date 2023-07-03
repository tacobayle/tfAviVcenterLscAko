resource "vsphere_content_library" "library" {
  count           = var.avi.config.vcenter.content_library.create == true ? 1 : 0
  name            = var.avi.config.vcenter.content_library.name
  storage_backing = [data.vsphere_datastore.datastore.id]
}

data "vsphere_content_library" "library" {
  count           = var.avi.config.vcenter.content_library.create == false ? 1 : 0
  name            = var.avi.config.vcenter.content_library.name
}