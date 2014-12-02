$('#user_search_radius_meters').val('')
# TODO handle errors
$('#comm_peer_data').html("<%= j render(partial: '/shared/peers', locals: { user: @user }) -%>")
