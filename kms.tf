resource "aws_kms_key" "lambda_env_key" {
  description = "Key for encrypting/decrypting Lambda environment variables *at rest* in Lambda functions related to our projects."
  tags {
    Name        = "tf-logging-aggregation-default"
    Description = "Default DevOps key for the tf-logging-aggregation project"
  }
}

data "aws_kms_secret" "devops_pagerduty_keys" {
  # These secrets were generated with the above key:
  # aws kms encrypt \
  #   --key-id REDACTED \
  #   --plaintext 'SECRET_STUFF_GOES_HERE' \
  #   --output text \
  #   --query CiphertextBlob \
  #   --profile ${whatever_profile_you_use}
  # This generates a large base64-encoded string, the payload(s) below
  secret {
    name = "test_pd_api_key"
    payload = "VERY_LONG_CIPHER1"
  }
  secret {
    name = "pd_api_key"
    payload = "VERY_LONG_CIPHER2"
  }
}

data "aws_kms_secret" "static_analysis_slack_tokens" {
  # These secrets were generated with the above key:
  # aws kms encrypt \
  #   --key-id REDACTED \
  #   --plaintext 'SECRET_STUFF_GOES_HERE' \
  #   --output text \
  #   --query CiphertextBlob \
  #   --profile ${whatever_profile_you_use}
  # This generates a large base64-encoded string, the payload(s) below
  secret {
    name = "devops_slack_token"
    payload = "VERY_LONG_CIPHER3"
  }
}

data "aws_kms_secret" "ecs_static_analysis_ec2_keypair" {
  # These secrets were generated with boto3:
  # session = boto3.Session(profile_name='devops')
  # kcli = session.client('kms')
  # with open('~/.ssh/ecs_static_analysis') as data:
  #    key = data.read()
  # result = kcli.encrypt(KeyId='REDACTED',
  #                       Plaintext=key)
  # cipherblob = result['CiphertextBlob']
  # printable = base64.b64encode(cipherblob)).decode('utf-8')
  # print(printable)
  # ----
  # It can be retrieved with:
  # session = boto3.Session(profile_name='devops')
  # kcli = session.client('kms')
  # printable = '''<pasted payload>'''
  # cipherblob = base64.b64decode(printable.encode('utf-8'))
  # decres = kcli.decrypt(CiphertextBlob=cipherblob)
  # print(decres['Plaintext'].decode('utf-8'))
  secret {
    name = "static_analysis_ecs_instance_private_key"
    payload = "ULTRA_LONG_CIPHER4"
  }
}
