# =============================================================================
# LOG DELIVERY RESOURCES
# =============================================================================

# Log delivery destinations
resource "aws_cloudwatch_log_delivery_destination" "this" {
  for_each = var.log_deliveries
  provider = aws.target_region

  name                      = "${var.name_prefix}${each.key}"
  delivery_destination_type = each.value.destination_type

  dynamic "delivery_destination_configuration" {
    for_each = each.value.destination_resource_arn != null ? [1] : []
    content {
      destination_resource_arn = each.value.destination_resource_arn
    }
  }
}

# Log delivery sources
resource "aws_cloudwatch_log_delivery_source" "this" {
  for_each = var.log_deliveries
  provider = aws.target_region

  name         = "${var.name_prefix}${each.key}"
  resource_arn = each.value.resource_arn
  log_type     = each.value.log_type
}

# Log deliveries
resource "aws_cloudwatch_log_delivery" "this" {
  for_each = var.log_deliveries
  provider = aws.target_region

  delivery_source_name     = aws_cloudwatch_log_delivery_source.this[each.key].name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.this[each.key].arn
}
