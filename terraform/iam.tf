resource "aws_iam_role" "ingest_lambda_role" {
    name_prefix = "role-${var.ingest_lambda_name}"
    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "sts:AssumeRole"
                ],
                "Principal": {
                    "Service": [
                        "lambda.amazonaws.com"
                    ]
                }
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "s3_document" {
    statement {
        actions = ["s3:PutObject"]

        resources = [
            "${aws_s3_bucket.ingested_data.arn}/*"
        ]
    }
}

data "aws_iam_policy_document" "cw_document" {
     statement {

    actions = [ "logs:CreateLogGroup" ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }

  statement {

    actions = [ "logs:CreateLogStream", "logs:PutLogEvents" ]

    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.ingest_lambda_name}:*"
    ]
  }
}

resource "aws_iam_policy" "sm_policy" {
  name = "sm_access_permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:secretsmanager:us-east-1:108554963036:secret:totesys-db-OM8d7g"
      },
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
    name_prefix = "s3-policy-${var.ingest_lambda_name}"
    policy = data.aws_iam_policy_document.s3_document.json
}


resource "aws_iam_policy" "cw_policy" {
    name_prefix = "cw-policy-${var.ingest_lambda_name}"
    policy = data.aws_iam_policy_document.cw_document.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
    role = aws_iam_role.ingest_lambda_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_cw_policy_attachment" {
    role = aws_iam_role.ingest_lambda_role.name
    policy_arn = aws_iam_policy.cw_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_sm_policy_attachment" {
    role = aws_iam_role.ingest_lambda_role.name
    policy_arn = aws_iam_policy.sm_policy.arn
}
