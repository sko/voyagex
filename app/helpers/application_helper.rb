module ApplicationHelper

  #
  #
  #
  def is_mobile
    #return true if true
    request.user_agent =~ /Mobile|webOS/
  end

end