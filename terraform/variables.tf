variable "mlflow_tracking_uri" {
  type        = string
  description = "The MLflow tracking server URI"
}

variable "epochs" {
  type        = string
  default = "1"
  description = "Epochs in integer string"
}