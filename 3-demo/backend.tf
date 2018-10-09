terraform {
  backend "s3" {
    key            = "3-demo.state"
    region         = "us-east-1"
    bucket         = "vpcdemo10112018-remotestate"
    dynamodb_table = "vpcdemo10112018-tfstatelock"
  }
}
