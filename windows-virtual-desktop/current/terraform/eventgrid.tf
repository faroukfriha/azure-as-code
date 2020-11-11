## Subscribing to the event generated by the expiration of the registration token
resource "azurerm_eventgrid_system_topic" "wvd" {
  name                   = var.wvd_events["topic_name"]
  location               = azurerm_resource_group.wvd.location
  resource_group_name    = azurerm_resource_group.wvd.name
  source_arm_resource_id = azurerm_key_vault.wvd.id
  topic_type             = var.wvd_events["topic_type"]
}

resource "azurerm_eventgrid_event_subscription" "wvd" {
  name                 = var.wvd_events["subscription_name"]
  scope                = azurerm_key_vault.wvd.id
  included_event_types = ["Microsoft.KeyVault.SecretsExpired"]
  depends_on           = [azurerm_function_app.wvd]

  azure_function_endpoint {
    function_id                       = "${azurerm_function_app.wvd[var.wvd_events["event_handler"]].id}/functions/Renew-RegistrationTokenAfterExpiration"
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }
}