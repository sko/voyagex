<%= window_prefix -%>$('.whoami-img').attr('src', '<%=current_user.foto.url-%>')
<%= window_prefix -%>VoyageX.Sandbox.instance().toogleUserFotoUpload()
