#<%= window_prefix -%>$('.whoami-img').attr('src', '<%=current_user.foto.url-%>')
curU = <%= window_prefix -%>APP.user()
userPhotoUrl = <%= window_prefix -%>Storage.Model._viewUserFoto curU
if (typeof userPhotoUrl == 'string') 
  curU.foto.url = userPhotoUrl
  <%= window_prefix -%>APP.storage().saveUser { id: curU.id, username: curU.username }, { foto: curU.foto }
  <%= window_prefix -%>APP.storage().saveCurrentUser curU
  <%= window_prefix -%>$('.whoami-img').attr('src', userPhotoUrl)
  <%= window_prefix -%>USERS.refreshUserPhoto curU
else if (typeof userPhotoUrl.then == 'function')
  # Assume we are dealing with a promise.
  userPhotoUrl.then (url) ->
      curU = <%= window_prefix -%>APP.user()
      curU.foto.url = url
      <%= window_prefix -%>APP.storage().saveUser { id: curU.id, username: curU.username }, { foto: curU.foto }
      <%= window_prefix -%>APP.storage().saveCurrentUser curU
      <%= window_prefix -%>$('.whoami-img').attr('src', url)
      <%= window_prefix -%>USERS.refreshUserPhoto curU
<%= window_prefix -%>VoyageX.Sandbox.instance().toogleUserFotoUpload()
