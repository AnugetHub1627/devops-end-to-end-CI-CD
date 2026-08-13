terraform {
  backend "s3" {
    bucket         = "anu-ci-cd-terraform-state-bucket"
    key            = "devops-e2e/terraform.tfstate"
    region         = "ap-south-1" # Use your targeted region
    encrypt        = true
    # Optional but highly recommended: DynamoDB for state locking
    # dynamodb_table = "ci-cd-terraform-lock-table" 
  }
}
