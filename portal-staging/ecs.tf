resource "aws_ecr_repository" "api" {
  name         = "${local.ecs_cluster}-api"
  force_delete = true
}

resource "aws_ecs_cluster" "main" {
  name = "${local.ecs_cluster}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.ecs_cluster}"
  retention_in_days = 30
}

# Fluent Bit config for the FireLens log router
locals {
  firelens_config = <<-EOT
[SERVICE]
    flush        1
    log_level    info
    storage.type filesystem

[OUTPUT]
    Name        opentelemetry
    Match       *
    Host        alloy-otlp.${local.domain_name}
    Port        4318
    TLS         Off
    logs_uri    /v1/logs
    log_response_payload true

[OUTPUT]
    Name                cloudwatch_logs
    Match               *
    region              ${local.region}
    log_group_name      ${aws_cloudwatch_log_group.api.name}
    log_stream_prefix   api/
    auto_create_group   true
  EOT
}

resource "aws_ecs_task_definition" "api" {
  family                   = "${local.ecs_cluster}-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    # FireLens router container: forward to Alloy (OTLP) and keep CloudWatch
    {
      name      = "log-router"
      image     = "public.ecr.aws/aws-observability/aws-for-fluent-bit:3.0.0"
      essential = true
      firelensConfiguration = {
        type = "fluentbit"
        options = {
          enable-ecs-log-metadata = "true"
          config-file-type        = "file"
          config-file-value       = "/fluent-bit/etc/custom.conf"
        }
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "log-router"
        }
      }
      memoryReservation = 128
      command = [
        "sh",
        "-c",
        <<-EOC
cat <<'EOF' > /fluent-bit/etc/custom.conf
${local.firelens_config}
EOF
exec /entrypoint.sh fluent-bit -c /fluent-bit/etc/custom.conf
EOC
      ]
    },

    # API container
    {
      name  = "api"
      image = "${aws_ecr_repository.api.repository_url}:latest"
      environment = [{
        name  = "NODE_ENV",
        value = local.environment
      }]
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awsfirelens"
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.api]
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${local.ecs_cluster}-ecs-tasks"
  description = "Allow inbound traffic from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "api" {
  name            = "${local.ecs_cluster}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_controller {
    type = "ECS"
  }

  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https,
    aws_lb_target_group.api
  ]
}

resource "aws_appautoscaling_target" "api" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "cpu-auto-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 80.0
  }
}
