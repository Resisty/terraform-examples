# Nexus Repository As An AWS ECS Service

This README is not intended as a full explanation of how this module works or
is implemented; that should be more or less obvious from the terraform
configuration files.

The contents of this README will serve as warnings and "gotchas" encountered in building something like this.
## Caveats
---

### Domain Registration and SSL

In order to request and validate the SSL certificate for the service, you must
first register a domain; see `variables.tf` and `acm.tf`. A variable
`route53_zone_name` is passed in as the name for which to request a certificate
and this name must be the registered domain.

Additionally: in the REDACTED documentation, it makes no mention of forwarding the
NS records, but you may need to copy the 4 nameservers from Route53 for the
domain you're creating and have them entered into DNS as part of the request you
create. The registrar should know what to do.

### Launch Configuration and Autoscaling Group Changes

The current implementation of Terraform does not support automatically updating launch configurations; you must destroy the autoscaling group to which it is attached, then the launch configuration itself, then re-apply with your changes.

For example:
```
python run_tf.py ${profile} -a destroy -e "--target aws_autoscaling_group.my_asg"
python run_tf.py ${profile} -a destroy -e "--target aws_launch_configuration.my_lc"
python run_tf.py ${profile} -a apply
```
