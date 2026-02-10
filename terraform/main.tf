# Definir el cloud provider 
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider
provider "aws" {
  region = var.aws_region
}

# -----------------------
# Datos: VPC y subnets
# -----------------------
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# -----------------------
# Security Groups (definidos PRIMERO)
# -----------------------

# Security Group para ALB (Load Balancer)
resource "aws_security_group" "alb_sg" {
  name        = "shape-app-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.aws_vpc.default.id

  # HTTP acceso en puerto 6767 desde cualquier lugar
  ingress {
    description = "HTTP API access on port 6767"
    from_port   = 6767
    to_port     = 6767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida a cualquier destino
  egress {
    description = "Outbound to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "shape-app-alb-sg"
    Project = "ShapeAPI"
  }
}

# Security Group para EC2 instances
resource "aws_security_group" "ec2_sg" {
  name        = "shape-app-ec2-sg"
  description = "Security group for Shape API EC2 instances"
  vpc_id      = data.aws_vpc.default.id

  # HTTP acceso solo desde el ALB
  ingress {
    description     = "HTTP from ALB"
    from_port       = 6767
    to_port         = 6767
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH acceso (opcional, para debugging)
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Salida a cualquier destino
  egress {
    description = "Outbound to internet"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "shape-app-ec2-sg"
    Project = "ShapeAPI"
  }
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name        = "shape-app-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  # Permitir acceso desde EC2 security group
  ingress {
    description     = "PostgreSQL from EC2 instances"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Name    = "shape-app-rds-sg"
    Project = "ShapeAPI"
  }
}

# -----------------------
# RDS PostgreSQL (definido ANTES de Launch Template)
# -----------------------
resource "aws_db_subnet_group" "default" {
  name       = "shape-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    Name    = "shape-db-subnet-group"
    Project = "ShapeAPI"
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = "shape-db"
  db_name              = "shapedb"
  engine               = "postgres"
  engine_version       = "15"
  instance_class       = var.rds_instance_type
  allocated_storage    = 20
  storage_type         = "gp2"
  storage_encrypted    = false
  
  username = var.db_username
  password = var.db_password
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  
  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  
  maintenance_window      = "sun:03:00-sun:04:00"
  backup_window          = "02:00-03:00"
  backup_retention_period = 7
  
  max_allocated_storage = 100
  performance_insights_enabled = true
  
  tags = {
    Name    = "shape-postgres-db"
    Project = "ShapeAPI"
  }
}

# -----------------------
# Application Load Balancer (definido ANTES de Target Group y ASG)
# -----------------------
resource "aws_lb" "shape_alb" {
  name               = "shape-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  enable_deletion_protection = false

  tags = {
    Name    = "shape-app-alb"
    Project = "ShapeAPI"
  }
}

# -----------------------
# Target Group
# -----------------------
resource "aws_lb_target_group" "shape_tg" {
  name        = "shape-app-tg"
  port        = 6767
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/shapes"
    port                = "6767"
    protocol            = "HTTP"
    matcher             = "200"
  }

  tags = {
    Name    = "shape-app-tg"
    Project = "ShapeAPI"
  }
}

# -----------------------
# Listener
# -----------------------
resource "aws_lb_listener" "shape_listener" {
  load_balancer_arn = aws_lb.shape_alb.arn
  port              = 6767
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.shape_tg.arn
  }
}

# -----------------------
# Launch Template (usa las referencias CORRECTAS)
# -----------------------
resource "aws_launch_template" "shape_lt" {
  name          = "shape-app-launch-template"
  description   = "Launch template for Shape API instances"
  instance_type = var.ec2_instance_type
  image_id      = "ami-0532be01f26a3de55"  # Amazon Linux 2023

  key_name = var.key_pair_name  # Opcional, puedes dejarlo vacío

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp2"
      delete_on_termination = true
    }
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              
              # Instalar Java 21
              sudo yum install -y java-21-amazon-corretto-headless
              
              # Instalar CloudWatch Agent para métricas
              sudo yum install -y amazon-cloudwatch-agent
              
              # Crear directorio para la aplicación
              sudo mkdir -p /opt/shape-app
              sudo chmod 755 /opt/shape-app
              
              # Descargar JAR desde GitHub
              cd /opt/shape-app
              sudo curl -L -o api-shapes.jar https://github.com/mapinedaf/grupal_cloud/releases/download/jar/api-shapes.jar
              
              # Crear script de inicio
              sudo bash -c 'cat > /etc/systemd/system/shape-app.service << "SERVICE_EOF"
              [Unit]
              Description=Shape API Application
              After=network.target
              
              [Service]
              Type=simple
              User=ec2-user
              WorkingDirectory=/opt/shape-app
              ExecStart=/usr/bin/java -jar api-shapes.jar
              Restart=always
              RestartSec=10
              Environment="SPRING_DATASOURCE_URL=jdbc:postgresql://${aws_db_instance.postgres.endpoint}/shapedb"
              Environment="SPRING_DATASOURCE_USERNAME=${var.db_username}"
              Environment="SPRING_DATASOURCE_PASSWORD=${var.db_password}"
              Environment="SERVER_PORT=6767"
              Environment="SPRING_JPA_HIBERNATE_DDL_AUTO=update"
              
              [Install]
              WantedBy=multi-user.target
              SERVICE_EOF'
              
              # Configurar permisos y habilitar servicio
              sudo chmod 644 /etc/systemd/system/shape-app.service
              sudo systemctl daemon-reload
              sudo systemctl enable shape-app.service
              sudo systemctl start shape-app.service
              
              # Configurar CloudWatch agent
              sudo bash -c 'cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << "CW_EOF"
              {
                "metrics": {
                  "metrics_collected": {
                    "mem": {
                      "measurement": [
                        "mem_used_percent"
                      ],
                      "metrics_collection_interval": 60
                    }
                  },
                  "append_dimensions": {
                    "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
                    "ImageId": "$${aws:ImageId}",
                    "InstanceId": "$${aws:InstanceId}",
                    "InstanceType": "$${aws:InstanceType}"
                  }
                }
              }
              CW_EOF'
              
              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
              EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "shape-api-instance"
      Project = "ShapeAPI"
    }
  }

  tags = {
    Name    = "shape-app-launch-template"
    Project = "ShapeAPI"
  }
}

# -----------------------
# Auto Scaling Group
# -----------------------
resource "aws_autoscaling_group" "shape_asg" {
  name                = "shape-app-asg"
  vpc_zone_identifier = data.aws_subnets.default.ids
  
  min_size            = var.min_instances
  max_size            = var.max_instances
  desired_capacity    = var.desired_instances
  
  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true
  
  target_group_arns = [aws_lb_target_group.shape_tg.arn]

  launch_template {
    id      = aws_launch_template.shape_lt.id
    version = "$Latest"
  }

  # Políticas de scaling
  tag {
    key                 = "Name"
    value               = "shape-api-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "ShapeAPI"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------
# Auto Scaling Policies
# -----------------------
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "shape-app-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.shape_asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "shape-app-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.shape_asg.name
}

# -----------------------
# CloudWatch Alarms
# -----------------------
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "shape-app-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.shape_asg.name
  }

  alarm_description = "Scale up if CPU > 70% for 2 periods"
  alarm_actions     = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "shape-app-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.shape_asg.name
  }

  alarm_description = "Scale down if CPU < 30% for 2 periods"
  alarm_actions     = [aws_autoscaling_policy.scale_down.arn]
}