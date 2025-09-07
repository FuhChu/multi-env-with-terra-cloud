resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-${var.app_name}-cluster"

  tags = {
    Name        = "${var.environment}-${var.app_name}-cluster"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "app" {
  name = "${var.environment}/${var.app_name}"

  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-ecr"
    Environment = var.environment
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.environment}-${var.app_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-${var.app_name}-ecs-task-execution-role"
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-${var.app_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-${var.app_name}-ecs-task-role"
    Environment = var.environment
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-${var.app_name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name        = var.app_name,
      image       = "${aws_ecr_repository.app.repository_url}:latest", # Placeholder, image will be pushed by CI/CD
      cpu         = var.fargate_cpu,
      memory      = var.fargate_memory,
      essential   = true,
      portMappings = [
        {
          containerPort = var.container_port,
          hostPort      = var.container_port
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options   = {
          "awslogs-group"         = aws_cloudwatch_log_group.app.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.environment}-${var.app_name}-task-def"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/ecs/${var.environment}/${var.app_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.environment}-${var.app_name}-log-group"
    Environment = var.environment
  }
}

resource "aws_lb" "app" {
  name               = "${var.environment}-${var.app_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name        = "${var.environment}-${var.app_name}-lb"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  name        = "${var.environment}-${var.app_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-tg"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "app_http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_security_group" "lb" {
  name        = "${var.environment}-${var.app_name}-lb-sg"
  description = "Allow HTTP access to ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-lb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.environment}-${var.app_name}-ecs-tasks-sg"
  description = "Allow inbound access to ECS tasks from ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-ecs-tasks-sg"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.environment}-${var.app_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = var.app_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [task_definition] # Ignore changes to task definition to allow CI/CD to update it
  }

  tags = {
    Name        = "${var.environment}-${var.app_name}-service"
    Environment = var.environment
  }
}