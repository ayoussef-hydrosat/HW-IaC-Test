run "network_no_public_ssh_rdp" {
  command = plan

  variables {
    is_test_mode_enabled = true
  }


  assert {
    condition     = anytrue([for r in aws_security_group.bastion.ingress : r.from_port == 22 && r.to_port == 22])
    error_message = "Bastion SG must allow SSH"
  }

  assert {
    condition     = alltrue([for r in aws_security_group.bastion.ingress : !(r.from_port == 3389 && r.to_port == 3389 && contains(r.cidr_blocks, "0.0.0.0/0"))])
    error_message = "Bastion SG must not allow public RDP"
  }
}
