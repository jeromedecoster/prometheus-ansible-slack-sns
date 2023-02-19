# https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource
resource "null_resource" "env_file" {

  triggers = {
    # everytime = uuid()
    key_id     = aws_iam_access_key.user_key.id
    key_secret = aws_iam_access_key.user_key.secret
    topic_arn  = aws_sns_topic.topic.arn
  }

  # https://developer.hashicorp.com/terraform/language/resources/provisioners/local-exec
  provisioner "local-exec" {
    command = "scripts/env-file.sh .env AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY SNS_TOPIC_ARN"

    working_dir = var.project_dir

    environment = {
      AWS_ACCESS_KEY_ID     = aws_iam_access_key.user_key.id
      AWS_SECRET_ACCESS_KEY = aws_iam_access_key.user_key.secret
      SNS_TOPIC_ARN         = aws_sns_topic.topic.arn
    }
  }
}
