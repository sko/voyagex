#<%= window_prefix -%>$('.whoami-img').attr('src', '<%=current_user.foto.url-%>')
userPhotoUrl = <%= window_prefix -%>Storage.Model._viewUserFoto <%= window_prefix -%>currentUser
if (typeof userPhotoUrl == 'string') 
  <%= window_prefix -%>currentUser.foto.url = userPhotoUrl
  <%= window_prefix -%>APP.storage().saveUser { id: <%= window_prefix -%>currentUser.id, username: <%= window_prefix -%>currentUser.username }, { foto: <%= window_prefix -%>currentUser.foto }
  <%= window_prefix -%>$('.whoami-img').attr('src', userPhotoUrl)
else if (typeof userPhotoUrl.then == 'function')
  # Assume we are dealing with a promise.
  userPhotoUrl.then (url) ->
      <%= window_prefix -%>currentUser.foto.url = userPhotoUrl
      # overwrite url
      <%= window_prefix -%>APP.storage().saveUser { id: <%= window_prefix -%>currentUser.id, username: <%= window_prefix -%>currentUser.username }, { foto: <%= window_prefix -%>currentUser.foto }
      <%= window_prefix -%>$('.whoami-img').attr('src', url)
<%= window_prefix -%>VoyageX.Sandbox.instance().toogleUserFotoUpload()
