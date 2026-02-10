output "alb_dns_name" {
  value       = aws_lb.shape_alb.dns_name
  description = "DNS name del Application Load Balancer"
}

output "application_url" {
  value       = "http://${aws_lb.shape_alb.dns_name}:6767"
  description = "URL de la aplicación (vía Load Balancer)"
}

output "rds_endpoint" {
  value       = aws_db_instance.postgres.endpoint
  description = "Endpoint de conexión a RDS"
}

output "asg_name" {
  value       = aws_autoscaling_group.shape_asg.name
  description = "Nombre del Auto Scaling Group"
}

output "current_instances" {
  value       = aws_autoscaling_group.shape_asg.desired_capacity
  description = "Número actual de instancias"
}

output "cloudwatch_alarms" {
  value = {
    scale_up  = aws_cloudwatch_metric_alarm.high_cpu.alarm_name
    scale_down = aws_cloudwatch_metric_alarm.low_cpu.alarm_name
  }
  description = "Nombres de las alarmas de CloudWatch"
}