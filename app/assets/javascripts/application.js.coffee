class window.VoyageX.NavBar
  @menuNavClick: (clickSrc) ->
    window.clientState.setView(window.clientState.getView(clickSrc))
    return false

  @showActiveState: (activeSelector = null) ->
    if APP.isOnline()
      color = '1f9600'
    else
      color = 'd91b00'
    $('#network_state_view').css('background-color', '#'+color)

  @showView: (view) ->
    if !$('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).addClass('active')
    $('#content_'+view.key).css('display', 'block')

  @hideView: (view) ->
    if $('#menu_'+view.key).hasClass('active')
      $('#menu_'+view.key).removeClass('active')
    $('#content_'+view.key).css('display', 'none')

window.clientState = new VoyageX.ClientState('map', 'camera', VoyageX.NavBar.showView, VoyageX.NavBar.hideView)

############################### popup ###
# signUpDialog
#
allSignUpFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))
addUser = () ->
  $("#new_user").submit()
  signUpDialog.dialog("close")
  return true
window.signUpDialog = $("#sign_up_modal").dialog({
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

############################### popup ###
# signInDialog
#
allSignInFields = $([]).add($("#auth_signin_email")).add($("#auth_signin_password"))
signInUser = () ->
  $("#new_session").submit()
  signInDialog.dialog("close")
  return true
window.signInDialog = $("#sign_in_modal").dialog({
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

############################### popup ###
# contextNavPanel
#
window.contextNavPanel = $("#context_nav_panel").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      top: ($(window).height()-Math.abs($(window).height() * 0.8))+'px',
      left: '0px',
      show: { effect: "drop", duration: 500 },
      hide: { effect: "fade", duration: 500 },
      modal: true
    })
#$("head").append("<style type='text/css'>#context_nav_panel {positon: fixed; top:"+($(window).height()-Math.abs($(window).height() * 0.8))+"px;}</style>");

############################### popup ###
# uploadDataDialog
#
window.uploadDataDialog = $("#upload_data_conrols").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      modal: true
    })
#$("head").append("<style type='text/css'>#sign_in_modal {width:"+Math.abs($(window).width() * 0.3)+"px;}</style>");

############################### popup ###
# attachmentViewPanel
#
window.attachmentViewPanel = $("#attachment_view_panel").dialog({
      autoOpen: false,
      height: Math.abs($(window).height() * 0.8),
      width: Math.abs($(window).width() * 0.5),
      modal: true
    })

############################### popup ###
# systemMessagePanel | systemMessagePopup
#
window.systemMessagePanel = $("#system_message_panel").dialog({
      #dialogClass: "no-close",
      autoOpen: false,
      height: Math.abs($(window).height() * 0.3),
      width: Math.abs($(window).width() * 0.25),
      modal: true
    })
window.systemMessagePopup = $("#system_message_popup").dialog({
      #dialogClass: "no-close",
      autoOpen: false,
      height: Math.abs($(window).height() * 0.3),
      width: Math.abs($(window).width() * 0.25),
      modal: true
    })

$("#context_nav_panel").tabs()