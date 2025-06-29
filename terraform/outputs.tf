output "vm_public_ip" {
  value = aws_instance.gpu_spot.public_ip
}