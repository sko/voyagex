class window.VoyageX.NavBar
  @menuNavClick: (clickSrc) ->
    window.clientState.setView(window.clientState.getView(clickSrc))
    return false

  @showView: (view) ->
    if !$('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).addClass('active')
    $('#content_'+view.key).css('display', 'block')

  @hideView: (view) ->
    if $('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).removeClass('active')
    $('#content_'+view.key).css('display', 'none')

window.clientState = new VoyageX.ClientState('map', 'camera', VoyageX.NavBar.showView, VoyageX.NavBar.hideView)

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
#$("head").append("<style type='text/css'>#sign_up_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

allSignInFields = $([]).add($("#auth_signin_email")).add($("#auth_signin_password"))
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
#$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

#window.uploadCommentDialog = $("#upload_comment_conrols").dialog({
#      autoOpen: false,
#      height: Math.abs($(window).height() * 0.8),
#      width: Math.abs($(window).width() * 0.5),
#      modal: true
#    })
#$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");
window.photoNavPanel = $("#photo_nav_panel").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      top: ($(window).height()-Math.abs($(window).height() * 0.8))+'px',
      left: '0px',
      show: { effect: "drop", duration: 500 },
      hide: { effect: "fade", duration: 500 },
      modal: true
    })
#$("head").append("<style type='text/css'>#photo_nav_panel {positon: fixed; top:"+($(window).height()-Math.abs($(window).height() * 0.8))+"px;}</style>");
window.uploadDataDialog = $("#upload_data_conrols").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      modal: true
    })
#$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

window.attachmentViewPanel = $("#attachment_view_panel").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      modal: true
    })

$("#photo_nav_panel").tabs()