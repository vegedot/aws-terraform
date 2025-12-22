module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.2.0"

  name               = "${var.project_name}-${var.environment}-alb-${var.alb_type}"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  security_groups    = [var.alb_sg_id]

  enable_deletion_protection = false

  # Target Group
  target_groups = {
    main = {
      name                 = "${var.project_name}-${var.environment}-tg-${var.alb_type}"
      backend_protocol     = "HTTP"
      backend_port         = var.backend_port
      target_type          = "ip"
      create_attachment    = false  # ECS manages targets dynamically
      deregistration_delay = 30
      health_check = {
        enabled             = true
        interval            = 30
        path                = var.health_check_path
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 2
        matcher             = "200"
      }
    }
  }

  # Listener
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "main"
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-${var.alb_type}"
  }
}
