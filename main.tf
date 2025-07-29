provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "strapi-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "strapi-subnet-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "strapi-subnet-b"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "pradyumnasg" {
  name        = "pradyumnasg"
  description = "Allow HTTP and Strapi"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/prady-strapi-v2"
  retention_in_days = 7
}

resource "aws_lb" "alb" {
  name               = "pradylb-2"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  security_groups    = [aws_security_group.pradyumnasg.id]
}

resource "aws_lb_target_group" "tg" {
  name        = "pradytg-v2"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/admin"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_cluster" "strapi_cluster" {
  name = "pradyumnacluster"
}

resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = "arn:aws:iam::607700977843:role/ecs-task-execution-role"

  container_definitions = jsonencode([{
    name  = "strapi"
    image = "nikampradyumna/strapi-app4:latest"
    portMappings = [{
      containerPort = 1337
      hostPort      = 1337
      protocol      = "tcp"
    }]
    environment = [
      { name = "HOST", value = "0.0.0.0" },
      { name = "PORT", value = "1337" },
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
      { name = "DATABASE_SSL_REJECT_UNAUTHORIZED", value = "false" },
      { name = "DATABASE_POOL_MIN", value = "0" },
      { name = "DATABASE_POOL_MAX", value = "5" },
      { name = "DATABASE_CONNECTION_TIMEOUT", value = "60000" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = "/ecs/prady-strapi"
        awslogs-region        = "us-east-2"
        awslogs-stream-prefix = "prady"
      }
    }
  }])
}

resource "aws_ecs_service" "strapi_service" {
  name            = "prady-service-2"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.pradyumnasg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "prady-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x    = 0,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "CPUUtilization", "ClusterName", "pradyumnacluster", "ServiceName", "prady-service" ]
          ],
          period = 60,
          stat = "Average",
          region = "us-east-2",
          title = "CPU Utilization"
        }
      },
      {
        type = "metric",
        x    = 12,
        y    = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "MemoryUtilization", "ClusterName", "pradyumnacluster", "ServiceName", "prady-service" ]
          ],
          period = 60,
          stat = "Average",
          region = "us-east-2",
          title = "Memory Utilization"
        }
      }
    ]
  })
}

