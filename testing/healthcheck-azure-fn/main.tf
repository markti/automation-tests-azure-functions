data "http" "index" {
  url    = var.endpoint
  method = "GET"
}
