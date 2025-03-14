output "mwaa_env_arn" {
  value = aws_mwaa_environment.mwaa_env.arn
}

output "mwaa_webserver_url" {
  value = aws_mwaa_environment.mwaa_env.webserver_url
}
