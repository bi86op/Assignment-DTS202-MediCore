# Current AWS account and Terraform IAM identity

data "aws_caller_identity" "current" {}


# Trust policy for the five assignment IAM roles
# Allows the current Terraform IAM user to assume these roles

data "aws_iam_policy_document" "assignment_role_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"

      identifiers = [
        data.aws_caller_identity.current.arn
      ]
    }
  }
}

# 1. Clinical Read-Only Role

resource "aws_iam_role" "clinical_read_only" {
  name               = "medicore-clinical-read-only"
  description        = "Provides read-only access to authorised clinical data"
  assume_role_policy = data.aws_iam_policy_document.assignment_role_trust.json

  tags = {
    Name    = "medicore-clinical-read-only"
    Purpose = "Clinical read-only access"
  }
}


# 2. Clinical Write Role

resource "aws_iam_role" "clinical_write" {
  name               = "medicore-clinical-write"
  description        = "Provides controlled read and write access to authorised clinical data"
  assume_role_policy = data.aws_iam_policy_document.assignment_role_trust.json

  tags = {
    Name    = "medicore-clinical-write"
    Purpose = "Clinical read and write access"
  }
}


# 3. Database Administrator Role

resource "aws_iam_role" "db_admin" {
  name               = "medicore-db-admin"
  description        = "Provides controlled administrative access to database services"
  assume_role_policy = data.aws_iam_policy_document.assignment_role_trust.json

  tags = {
    Name    = "medicore-db-admin"
    Purpose = "Database administration"
  }
}


# 4. Monitoring-Only Role

resource "aws_iam_role" "monitoring_only" {
  name               = "medicore-monitoring-only"
  description        = "Provides read-only access to monitoring metrics, logs and alarms"
  assume_role_policy = data.aws_iam_policy_document.assignment_role_trust.json

  tags = {
    Name    = "medicore-monitoring-only"
    Purpose = "Monitoring and incident visibility"
  }
}


# 5. Backup Operator Role

resource "aws_iam_role" "backup_operator" {
  name               = "medicore-backup-operator"
  description        = "Provides controlled access to create and manage authorised backups"
  assume_role_policy = data.aws_iam_policy_document.assignment_role_trust.json

  tags = {
    Name    = "medicore-backup-operator"
    Purpose = "Backup operations"
  }
}

# Technical IAM role used by the bastion EC2 instance
# to send operating system and SSH authentication logs
# to Amazon CloudWatch Logs.

data "aws_iam_policy_document" "bastion_cloudwatch_trust" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "bastion_cloudwatch" {
  name               = "medicore-bastion-cloudwatch-role"
  description        = "Allows the MediCore bastion host to publish SSH authentication logs to CloudWatch."
  assume_role_policy = data.aws_iam_policy_document.bastion_cloudwatch_trust.json

  tags = {
    Name        = "medicore-bastion-cloudwatch-role"
    Project     = "MediCore"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Tier        = "Management"
  }
}

resource "aws_iam_role_policy_attachment" "bastion_cloudwatch_agent" {
  role       = aws_iam_role.bastion_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "bastion_cloudwatch" {
  name = "medicore-bastion-cloudwatch-profile"
  role = aws_iam_role.bastion_cloudwatch.name

  tags = {
    Name        = "medicore-bastion-cloudwatch-profile"
    Project     = "MediCore"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Tier        = "Management"
  }
}

# Least-privilege permissions for the Clinical Read-Only role.

data "aws_iam_policy_document" "clinical_read_only_permissions" {
  statement {
    sid    = "ListMediCoreClinicalBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.medicore_data.arn
    ]
  }

  statement {
    sid    = "ReadMediCoreClinicalObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.medicore_data.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "clinical_read_only" {
  name   = "medicore-clinical-read-only-policy"
  role   = aws_iam_role.clinical_read_only.id
  policy = data.aws_iam_policy_document.clinical_read_only_permissions.json
}

# Least-privilege permissions for the Clinical Write role.

data "aws_iam_policy_document" "clinical_write_permissions" {
  statement {
    sid    = "ListMediCoreClinicalBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.medicore_data.arn
    ]
  }

  statement {
    sid    = "ReadAndWriteMediCoreClinicalObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.medicore_data.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "clinical_write" {
  name   = "medicore-clinical-write-policy"
  role   = aws_iam_role.clinical_write.id
  policy = data.aws_iam_policy_document.clinical_write_permissions.json
}

# Least-privilege permissions for the Database Administrator role.

data "aws_iam_policy_document" "db_admin_permissions" {
  statement {
    sid    = "ViewRDSConfiguration"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots",
      "rds:DescribeDBSubnetGroups",
      "rds:ListTagsForResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ManageMediCoreDatabase"
    effect = "Allow"

    actions = [
      "rds:ModifyDBInstance",
      "rds:RebootDBInstance",
      "rds:CreateDBSnapshot",
      "rds:RestoreDBInstanceFromDBSnapshot"
    ]

    resources = [
      aws_db_instance.medicore.arn
    ]
  }
}

resource "aws_iam_role_policy" "db_admin" {
  name   = "medicore-db-admin-policy"
  role   = aws_iam_role.db_admin.id
  policy = data.aws_iam_policy_document.db_admin_permissions.json
}

# Read-only monitoring permissions for CloudWatch and CloudWatch Logs.

data "aws_iam_policy_document" "monitoring_only_permissions" {
  statement {
    sid    = "ReadCloudWatchMonitoring"
    effect = "Allow"

    actions = [
      "cloudwatch:DescribeAlarms",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListDashboards",
      "cloudwatch:ListMetrics"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "ReadCloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "logs:GetLogEvents",
      "logs:StartQuery",
      "logs:GetQueryResults",
      "logs:StopQuery"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "monitoring_only" {
  name   = "medicore-monitoring-read-only-policy"
  role   = aws_iam_role.monitoring_only.id
  policy = data.aws_iam_policy_document.monitoring_only_permissions.json
}

# Least-privilege permissions for the Backup Operator role.

data "aws_iam_policy_document" "backup_operator_permissions" {
  statement {
    sid    = "ListMediCoreBackupBucket"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.medicore_data.arn
    ]
  }

  statement {
    sid    = "ManageMediCoreBackupObjects"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.medicore_data.arn}/*"
    ]
  }

  statement {
    sid    = "ViewRDSSnapshots"
    effect = "Allow"

    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBSnapshots"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "CreateMediCoreDatabaseSnapshots"
    effect = "Allow"

    actions = [
      "rds:CreateDBSnapshot"
    ]

    resources = [
      aws_db_instance.medicore.arn
    ]
  }
}

resource "aws_iam_role_policy" "backup_operator" {
  name   = "medicore-backup-operator-policy"
  role   = aws_iam_role.backup_operator.id
  policy = data.aws_iam_policy_document.backup_operator_permissions.json
}