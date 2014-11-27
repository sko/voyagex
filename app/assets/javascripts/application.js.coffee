//= require upload_helper

class window.NavBar
  @SELECTED_CONTENT: 'map'
  
  @menuNavClick: (clickSrc) ->
    if clickSrc == NavBar.SELECTED_CONTENT
      return
    if (clickSrc == 'chat')
      for view in ['map', 'home']
        if $('#menu_'+view).hasClass('active')
          $('#menu_'+view).removeClass('active')
        $('#content_'+view).css('display', 'none')
      if !$('#menu_'+clickSrc).hasClass('active')
        $('#menu_'+clickSrc).addClass('active')
      $('#content_'+clickSrc).css('display', 'block')
    else if (clickSrc == 'map')
      for view in ['chat', 'home']
        if $('#menu_'+view).hasClass('active')
          $('#menu_'+view).removeClass('active')
        $('#content_'+view).css('display', 'none')
      if !$('#menu_'+clickSrc).hasClass('active')
        $('#menu_'+clickSrc).addClass('active')
      $('#content_'+clickSrc).css('display', 'block')
    else if (clickSrc == 'home')
      for view in ['chat', 'map']
        if $('#menu_'+view).hasClass('active')
          $('#menu_'+view).removeClass('active')
        $('#content_'+view).css('display', 'none')
      if !$('#menu_'+clickSrc).hasClass('active')
        $('#menu_'+clickSrc).addClass('active')
      $('#content_'+clickSrc).css('display', 'block')
    NavBar.SELECTED_CONTENT = clickSrc
    return false

  @linkFor: (path, lang, params) ->
    path + '?l=' + lang + '&c=' + NavBar.SELECTED_CONTENT + (params == '' ? '' : '&'+params)

  $('#content_chat').css('display', 'none')
  $('#content_map').css('display', 'block')
  $('#content_home').css('display', 'none')
#  for id in home_partial_ids
#    $('#'+id).css('display', 'none')

allSignUpFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))

addUser = () ->
  $("#new_user").submit()
  signUpDialog.dialog("close")
  return true

signUpDialog = $("#sign_up_modal").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.7),
      width: Math.abs($(window).width() * 0.3),
      modal: true,
      buttons: {
        "Create an account": addUser,
        Cancel: () ->
          signUpDialog.dialog("close")
      },
      close: () ->
        $("#new_user")[0].reset()
        allSignUpFields.removeClass("ui-state-error")
        $("#sign_up_error").html('')
    })
$("head").append("<style type='text/css'>#sign_up_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

allSignInFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))

signInUser = () ->
  $("#new_session").submit()
  signInDialog.dialog("close")
  return true

signInDialog = $("#sign_in_modal").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.7),
      width: Math.abs($(window).width() * 0.3),
      modal: true,
      buttons: {
        "Sign In": signInUser,
        Cancel: () ->
          signInDialog.dialog("close")
      },
      close: () ->
        $("#new_session")[0].reset()
        allSignInFields.removeClass("ui-state-error")
        $("#sign_in_error").html('')
    })
$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

window.uploadCommentDialog = $("#upload_comment_conrols").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      modal: true
    })
$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");
