package terraform
import rego.v1

is_public_cidr(cidr) if { cidr == "0.0.0.0/0" }
is_public_cidr(cidr) if { cidr == "::/0" }

has_public_cidr(list) if {
  list[_] == "0.0.0.0/0"
}

has_public_cidr(list) if {
  list[_] == "::/0"
}

has_action(rc, action) if {
  rc.change.actions[_] == action
}
