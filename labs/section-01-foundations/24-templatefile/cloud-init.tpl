# This is a cloud-init config (not Terraform). Terraform's templatefile() reads
# it and substitutes the hostname var, then loops over the packages var.
# NOTE: raw template markers in comments would be parsed as directives, so
# this comment spells them out in words instead.
#cloud-config
hostname: ${hostname}
package_update: true
packages:
%{ for p in packages ~}
  - ${p}
%{ endfor ~}
runcmd:
  - systemctl enable --now nginx
  - echo "host: $(hostname) built by templatefile()" > /var/www/html/index.html
