terraform {
  backend "s3" {
    key = "4-demo-network.state"
    region = "us-east-1"
    bucket = "vpcdemo10112018-remotestate"
    dynamodb_table = "vpcdemo10112018-tfstatelock"
  }
}