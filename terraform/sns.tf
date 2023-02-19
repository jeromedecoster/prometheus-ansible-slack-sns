resource "aws_sns_topic" "topic" {
  name = var.project_name
}

resource "aws_sns_topic_subscription" "subscription_email" {
  endpoint  = var.sns_email
  protocol  = "email"
  topic_arn = aws_sns_topic.topic.arn
}