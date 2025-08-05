provider "aws" {
  region = "us-east-2"
}

data "aws_vpc" "default" {
  id = "vpc-0784c474c9202d965"
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "strapi" {
  name               = "prady-alb2"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = ["sg-088f6f0f8b64b6b60"]
}

resource "aws_lb_target_group" "pradyumnatg_blue" {
  name        = "pradyumnatg-blue-2"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/_health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group" "pradyumnatg_green" {
  name        = "pradyumnatg-green-2"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/_health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "blue_listener" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.pradyumnatg_blue.arn
  }
}

resource "aws_ecs_cluster" "strapi" {
  name = "pradyumnacluster"
}

# IAM role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


# ✅ IAM role for CodeDeploy
resource "aws_iam_role" "codedeploy_role" {
  name = "CodeDeployServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}


resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([{
    name  = "strapi"
    image = "nikampradyumna/strapi-app4:latest"
    portMappings = [{
      containerPort = 1337
      protocol      = "tcp"
    }]
    environment = [
      { name = "HOST", value = "0.0.0.0" },
      { name = "PORT", value = "1337" },
      { name = "NODE_ENV", value = "development" },
      { name = "APP_KEYS", value = "qsw1!23,Qwe@456,Asd#789,Zxc$000" },
      { name = "API_TOKEN_SALT", value = "Fh9d12nV78xQplK0" },
      { name = "ADMIN_JWT_SECRET", value = "JwTAdm1nS3cr3tXyz@2025" },
      { name = "TRANSFER_TOKEN_SALT", value = "Tr4nsf3rS4ltT0k3n!" },
      { name = "JWT_SECRET", value = "JwTSecretK3y_ProdUse123" },
      { name = "ENCRYPTION_KEY", value = "EncRyptKey!2025#XyZ" },
      { name = "DATABASE_CLIENT", value = "postgres" },
      { name = "DATABASE_HOST", value = "pradyumnadb3.cbymg2mgkcu2.us-east-2.rds.amazonaws.com" },
      { name = "DATABASE_PORT", value = "5432" },
      { name = "DATABASE_NAME", value = "postgres" },
      { name = "DATABASE_USERNAME", value = "Pradyumna" },
      { name = "DATABASE_PASSWORD", value = "Dontknow$42!" },
      { name = "DATABASE_SSL", value = "true" },
      { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" }
    ]
  }])
}

resource "aws_codedeploy_app" "strapi" {
  name             = "strapi-codedeploy-app-v2"
  compute_platform = "ECS"
}

resource "aws_ecs_service" "strapi" {
  name            = "strapi-bluegreen-service"
  cluster         = aws_ecs_cluster.strapi.id
  launch_type     = "FARGATE"
  desired_count   = 1
  task_definition = aws_ecs_task_definition.strapi.arn

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = ["sg-088f6f0f8b64b6b60"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.pradyumnatg_blue.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [
    aws_lb_listener.blue_listener,
    aws_codedeploy_app.strapi
  ]
}

resource "aws_codedeploy_deployment_group" "strapi" {
  app_name               = aws_codedeploy_app.strapi.name
  deployment_group_name  = "strapi-bluegreen-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
    deployment_type   = "BLUE_GREEN"
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout    = "CONTINUE_DEPLOYMENT"
      wait_time_in_minutes = 0
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi.name
    service_name = aws_ecs_service.strapi.name
  }

  load_balancer_info {
    target_group_pair_info {
      target_group {
        name = aws_lb_target_group.pradyumnatg_blue.name
      }
      target_group {
        name = aws_lb_target_group.pradyumnatg_green.name
      }
      prod_traffic_route {
        listener_arns = [aws_lb_listener.blue_listener.arn]
      }
    }
  }
}

resource "aws_iam_role_policy" "codedeploy_ecs_inline" {
  name = "CodeDeployECSPermissions"
  role = aws_iam_role.codedeploy_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecs:DescribeServices",
          "ecs:UpdateService",
          "ecs:ListTasks",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "autoscaling:CompleteLifecycleAction",
          "autoscaling:DeleteLifecycleHook",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLifecycleHooks",
          "autoscaling:PutLifecycleHook",
          "autoscaling:RecordLifecycleActionHeartbeat",
          "autoscaling:ResumeProcesses",
          "autoscaling:SuspendProcesses",
          "autoscaling:UpdateAutoScalingGroup",
          "iam:PassRole"
        ],
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}
