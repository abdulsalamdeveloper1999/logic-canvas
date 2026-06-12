class FreePlan {
  // Free-tier icon filenames. Categories are inferred from filename prefixes
  // (aws- / azure- / gcp-).
  static const List<String> basicIconFileNames = [
    // AWS
    "aws-lambda.svg",
    "aws-ec2.svg",
    "aws-simple-storage-service.svg",
    "aws-dynamodb.svg",
    "aws-api-gateway.svg",
    "aws-identity-and-access-management.svg",
    "aws-cloudwatch.svg",
    "aws-rds.svg",
    // Azure
    "azure-virtual-machine.svg",
    "azure-function-apps.svg",
    "azure-cosmos-db.svg",
    "azure-active-directory.svg",
    "azure-sql-database.svg",
    "azure-storage-accounts.svg",
    "azure-virtual-networks.svg",
    "azure-app-services.svg",
    // GCP
    "gcp-compute-engine.svg",
    "gcp-cloud-functions.svg",
    "gcp-cloud-storage.svg",
    "gcp-bigquery.svg",
    "gcp-cloud-run.svg",
    "gcp-cloud-sql.svg",
    "gcp-identity-and-access-management.svg",
    "gcp-pubsub.svg",
  ];

  static bool isBasicIconPath(String path) {
    // Paths look like: assets/icons/<category>/<file>.
    final file = path.split('/').isNotEmpty ? path.split('/').last : path;
    return basicIconFileNames.contains(file);
  }
}
