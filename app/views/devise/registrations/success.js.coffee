<% if devise_mapping.confirmable? && (!resource.confirmed?) -%>
$("#sign_in_flash").html("<%= t('auth.email_confirm_required', email: resource.unconfirmed_email).gsub(/"/, '\\"') -%>")
<% end -%>
<% if is_mobile -%>
$('#sign_up_cancel').click()
$(".login-link > .ui-link").first().click()
<% else -%>
$("#sign_in_modal").dialog("open")
<% end -%>
