terraform {
  backend "s3" {
    bucket         = "agentcore-tfstate-<YOUR-ACCOUNT-ID>"  //Replace <YOUR-ACCOUNT-ID> with your actual AWS account ID
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
