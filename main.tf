# 1: Define required provider details
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# 2: Define AWS Credentials
provider "aws" {
    region = "eu-west-2"
    # shared_config_files      = ["~/.aws/config"]
    # shared_credentials_files = ["~/.aws/credentials"]
    # ^^ commented out as using environment variables
}

# 3: Define AWS IAM User
resource "aws_iam_user" "admin-user" {
    name = "2i_dm"
    tags = {
        description = "2i related admin group user on dm21 account"
  }
}

# 4: Define AWS resources to provision an image repository
resource "aws_ecr_repository" "app_ecr_repo" {
  name = "my-lovely-horse"
}

# 5: Define AWS resources to provision a cluster
resource "aws_ecs_cluster" "my_cluster" {
  name = "app-repo"
}

# 6: Define AWS resources to run the container
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-first-task"
  container_definitions    = <<DEFINITION
  [
    {
      "name": "app-first-task",
      "image": "${aws_ecr_repository.app_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000
        }
      ],
      "memory": 512,
      "cpu": 256
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Make use of Fargate as the launch type.
  network_mode             = "awsvpc"    # Add the AWS VPN network mode. Fargate requires this.
  memory                   = 512         # Container RAM
  cpu                      = 256         # Container Processor
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}

# 7: Define AWS task execution role and role assumption (1)
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

# 8: Define AWS task execution role and role assumption (2)
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# 9: Define AWS task execution role and role assumption (3)
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 10: Define reference to the default VPC
resource "aws_default_vpc" "default_vpc" {
}

# 11: Define reference to default subnet a
resource "aws_default_subnet" "default_subnet_a" {
  # Use your own region here but reference to subnet 1a
  availability_zone = "eu-west-2a"
}

# 12: Define reference to default subnet b
resource "aws_default_subnet" "default_subnet_b" {
  # Use your own region here but reference to subnet 1b
  availability_zone = "eu-west-2b"
}

# 13: Define a load balancer
resource "aws_alb" "application_load_balancer" {
  name               = "load-balancer-dev" #load balancer name
  load_balancer_type = "application"
  subnets = [ # Referencing the default subnets
    "${aws_default_subnet.default_subnet_a.id}",
    "${aws_default_subnet.default_subnet_b.id}"
  ]
  # security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

# 14: Define the security group for the load balancer
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # <-- Permits inbound traffic from all sources
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 15: Define VPC to load balancer link (1)
resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_default_vpc.default_vpc.id}" # <-- Default VPC
}

# 16: Define VPC to load balancer link (2)
resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # <-- Load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # <-- Target group
  }
}

# 17: Define the ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "app-first-service"     # Name the service
  cluster         = "${aws_ecs_cluster.my_cluster.id}"   # Reference the created Cluster
  task_definition = "${aws_ecs_task_definition.app_task.arn}" # Reference the task that the service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Set up the number of containers to 3

  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Reference the target group
    container_name   = "${aws_ecs_task_definition.app_task.family}"
    container_port   = 3000 # Specify the container port
  }

  network_configuration {
    subnets          = ["${aws_default_subnet.default_subnet_a.id}", "${aws_default_subnet.default_subnet_b.id}"]
    assign_public_ip = true     # Provide the containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"] # Set up the security group
  }
}

# 18: Define security group to permit traffic from the load balancer
resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 19: Define a logger for the load balancer app URL
output "app_url" {
  value = aws_alb.application_load_balancer.dns_name
}
