//= require upload_helper

class window.NavBar
  @menuNavClick: (clickSrc) ->
    if (clickSrc == 'chat')
      $('#content_im').css('display', 'block')
      $('#content_map').css('display', 'none')
      $('#content_home').css('display', 'none')
    else if (clickSrc == 'map')
      $('#content_im').css('display', 'none')
      $('#content_map').css('display', 'block')
      $('#content_home').css('display', 'none')
    else if (clickSrc == 'upload')
      $('#content_im').css('display', 'none')
      $('#content_map').css('display', 'none')
      $('#content_home').css('display', 'block')
    return false

  $('#content_im').css('display', 'none')
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
