resource "aws_iam_role" "ec2_ml_train_role" {
  name = "ec2-ml-train-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_access_policy" {
  name = "DVC-S3-Access-Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      Resource = [
        "arn:aws:s3:::dvc-datastore-dev-04062025",
        "arn:aws:s3:::dvc-datastore-dev-04062025/*",
        "arn:aws:s3:::mlflow-model-artifact-store-dev-04062025",
        "arn:aws:s3:::mlflow-model-artifact-store-dev-04062025/*"
      ]
    }]
  })
}

resource "aws_iam_policy" "ecr_read_policy" {
  name = "ECR-Read-Access-Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings"
        ],
        "Resource": [
          "arn:aws:ecr:ap-south-1:970547335250:repository/mlops_train_box"
        ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.ec2_ml_train_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach_ecr_policy" {
  role       = aws_iam_role.ec2_ml_train_role.name
  policy_arn = aws_iam_policy.ecr_read_policy.arn
}

resource "aws_iam_instance_profile" "dvc_instance_profile" {
  name = "dvc-ec2-instance-profile"
  role = aws_iam_role.ec2_ml_train_role.name
}