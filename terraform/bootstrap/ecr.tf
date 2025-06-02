resource "aws_ecr_repository" "knot_takehome" {
  name                 = "knot-takehome"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = "production"
    Project     = "knot-takehome"
  }
}

resource "aws_ecr_lifecycle_policy" "knot_takehome" {
  repository = aws_ecr_repository.knot_takehome.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
