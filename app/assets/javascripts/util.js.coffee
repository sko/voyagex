jQuery ->
  $.fn.selectRange = (start, end) ->
    if !end
      end = start
    this.each () ->
      if this.setSelectionRange
        this.focus()
        this.setSelectionRange(start, end)
      else if this.createTextRange
        range = this.createTextRange()
        range.collapse(true)
        range.moveEnd('character', end)
        range.moveStart('character', start)
        range.select()

  allSignUpFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))

  addUser = () ->
    $("#new_user").submit()
    signUpDialog.dialog("close")
    return true
  
  signUpDialog = $("#sign_up_modal").dialog({
        autoOpen: false,
        height: 300,
        width: 350,
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
  
#  signUpForm = signUpDialog.find("form").on 'submit', ( event ) ->
#           event.preventDefault()
#           addUser()

  allSignInFields = $([]).add($("#auth_email")).add($("#auth_password")).add($("#auth_password_confirmation"))

  signInUser = () ->
    $("#new_session").submit()
    signInDialog.dialog("close")
    return true
  
  signInDialog = $("#sign_in_modal").dialog({
        autoOpen: false,
        height: 300,
        width: 350,
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
  
#  signInForm = signInDialog.find("form").on 'submit', ( event ) ->
#           event.preventDefault()
#           signInUser()
