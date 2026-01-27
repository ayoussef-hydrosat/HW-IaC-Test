run "ecs_task_sizing" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_ecs_task_definition.api.cpu >= 256
    error_message = "ECS task CPU must be >= 256"
  }

  assert {
    condition     = aws_ecs_task_definition.api.memory >= 512
    error_message = "ECS task memory must be >= 512"
  }

  assert {
    condition     = length([for s in aws_ecs_cluster.main.setting : s if s.name == "containerInsights" && s.value == "enabled"]) > 0
    error_message = "ECS cluster must enable container insights"
  }

  assert {
    condition     = aws_cloudwatch_log_group.api.retention_in_days >= 30
    error_message = "CloudWatch log retention must be >= 30 days"
  }

  assert {
    condition     = aws_appautoscaling_policy.api_cpu.policy_type == "TargetTrackingScaling"
    error_message = "Autoscaling policy must be TargetTrackingScaling"
  }
}

run "ecs_firelens" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_ecs_task_definition.api.network_mode == "awsvpc"
    error_message = "ECS task must use awsvpc network mode"
  }
}

run "ecs_service_scaling" {
  command = plan

  variables {
    enable_cert_validation_records = false
    enable_k8s_resources           = false
  }


  assert {
    condition     = aws_ecs_service.api.desired_count >= 2
    error_message = "ECS desired_count must be >= 2"
  }

  assert {
    condition     = aws_appautoscaling_target.api.min_capacity <= aws_ecs_service.api.desired_count
    error_message = "Autoscaling min must be <= desired_count"
  }

  assert {
    condition     = aws_appautoscaling_target.api.max_capacity >= aws_ecs_service.api.desired_count
    error_message = "Autoscaling max must be >= desired_count"
  }

  assert {
    condition     = aws_appautoscaling_target.api.min_capacity >= 1
    error_message = "Autoscaling min must be >= 1"
  }

  assert {
    condition     = aws_appautoscaling_target.api.min_capacity <= aws_appautoscaling_target.api.max_capacity
    error_message = "Autoscaling min must be <= max"
  }
}
