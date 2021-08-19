resource "local_file" "wkc_sub_yaml" {
  content  = data.template_file.wkc_sub.rendered
  filename = "${local.cpd_workspace}/wkc_sub.yaml"
}

resource "local_file" "wkc_cr_yaml" {
  content  = data.template_file.wkc_cr.rendered
  filename = "${local.cpd_workspace}/wkc_cr.yaml"
}

resource "local_file" "sysctl_worker_yaml" {
  content  = data.template_file.sysctl_worker.rendered
  filename = "${local.cpd_workspace}/sysctl_worker.yaml"
}

resource "local_file" "db2u_operator_yaml" {
  content  = data.template_file.db2u_operator.rendered
  filename = "${local.cpd_workspace}/db2u_operator.yaml"
}

resource "null_resource" "install_wkc" {
  count = var.watson_knowledge_catalog == "yes" ? 1 : 0
  triggers = {
    namespace     = var.cpd_namespace
    cpd_workspace = local.cpd_workspace
  }
  provisioner "local-exec" {
    command = <<-EOF
echo "Creating WKC Operator"
oc create -f ${self.triggers.cpd_workspace}/wkc_sub.yaml
bash cpd/scripts/pod-status-check.sh ibm-cpd-wkc-operator ${local.operator_namespace}

echo 'Create WKC Core CR'
oc create -f ${self.triggers.cpd_workspace}/wkc_cr.yaml

echo 'check the WKC Core cr status'
bash cpd/scripts/check-cr-status.sh wkc wkc-cr ${var.cpd_namespace} wkcStatus
EOF
  }
  depends_on = [
    local_file.wkc_cr_yaml,
    local_file.db2u_operator_yaml,
    null_resource.install_aiopenscale,
    null_resource.install_wml,
    null_resource.install_ws,
    null_resource.install_spss,
    null_resource.install_dv,
    null_resource.install_cde,
    null_resource.configure_cluster,
    null_resource.cpd_foundational_services,
    null_resource.login_cluster,
    null_resource.install_db2aaservice,
  ]
}
