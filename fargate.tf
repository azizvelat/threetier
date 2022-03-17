locals {
  service_name = "example"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

module "service" {
  source  = "stroeer/ecs-fargate/aws"
  version = "0.19.0"

  assign_public_ip           = true
  cluster_id                 = aws_ecs_cluster.main.id
  container_port             = 80
  create_deployment_pipeline = false
  desired_count              = 1
  service_name               = local.service_name
  vpc_id                     = "vpc-063d33c2607f516b9"

  target_groups = [
    {
      name             = "${local.service_name}-public"
      backend_port     = 80
      backend_protocol = "HTTP"
      target_type      = "ip"
      health_check = {
        enabled = true
        path    = "/"
      }
    }
  ]

  https_listener_rules = [{
    listener_arn = aws_lb_listener.http.arn

    priority = 42
    actions = [{
      type               = "forward"
      target_group_index = 0
    }]
    conditions = [{
      path_patterns = ["/"]
    }]
  }]

  container_definitions = jsonencode([
    {
      command : [
        "/bin/sh -c \"echo '<html> <head> <title>Hello from httpd service</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p> </div></body></html>' >  /usr/local/apache2/htdocs/index.html && httpd-foreground\""
      ],
      cpu : 256,
      entryPoint : ["sh", "-c"],
      essential : true,
      image : "httpd:2.4",
      memory : 512,
      name : local.service_name,
      portMappings : [{
        containerPort : 80
        hostPort : 80
        protocol : "tcp"
      }]
    }
  ])

  //   ecr = {
  //     image_tag_mutability         = "IMMUTABLE"
  //     image_scanning_configuration = {
  //       scan_on_push = true
  //     }
  //   }
}