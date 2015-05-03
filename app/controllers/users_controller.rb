class UsersController < ApplicationController 
  include GeoUtils
  include ApplicationHelper
  include PoiHelper
  include UserHelper

  #protect_from_forgery :except => :change_details 
  skip_before_action :verify_authenticity_token, if: :any_request?

  def update
    @user = current_user
    Rails.logger.error "##################### @user = #{@user}, session[:provider] = #{session[:provider]}"
    # unless @user.present?
    #   @user = User.find(params[:id])
    #   #unless @user.identities
    # end

    @subscription_grant_requests = []
    @quit_subscriptions = []
    @cancel_subscription_requests = []
    @subscription_granted = []
    @subscription_grant_revoked = []
    @subscription_denied = []

    if params[:follow].present?
      peer_ids = params[:follow][:comm_peer_ports].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_ids[0].each do |peer_id|
        peer_port = CommPort.where(user_id: peer_id).first
        unless peer_port.comm_peers.find{|c_p|c_p.peer_id==@user.id}
          @subscription_grant_requests << peer_port.user
          peer_port.comm_peers.create(peer_id: @user.id)
          # notify peer that @user requests subscription-grant
          peer_sys_channel_enc_key = peer_port.sys_channel_enc_key
          #msg = { type: :subscription_grant_request, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_port.channel_enc_key } }
          msg = { type: :subscription_grant_request, peer: peer_json(@user.comm_port, { wants_to_follow_me: true }) }
          add_foto_to_msg @user, msg
          #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
        end
      end
      peer_ids[1].each do |peer_id|
        peer_port = CommPort.where(user_id: peer_id).first
        comm_peer = peer_port.comm_peers.find{|c_p|c_p.peer_id==@user.id}
        if comm_peer.present?
          comm_peer.destroy
          if comm_peer.granted_by_user
            @quit_subscriptions << peer_port
            #@un_subscribe << peer_port.channel_enc_key 
            # notify peer that @user does not follow anymore
            peer_sys_channel_enc_key = peer_port.sys_channel_enc_key
            msg = { type: :quit_subscription, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_port.channel_enc_key } }
            #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
            comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
          else
            @cancel_subscription_requests << peer_port.user
            # notify peer that @user does not request grant anymore
            peer_sys_channel_enc_key = peer_port.sys_channel_enc_key
            msg = { type: :cancel_subscription_grant_request, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_port.channel_enc_key } }
            #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
            comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
          end
        end
      end
    end
    if params[:grant].present?
      # comm_peer expected 
      # when a peer requests a grant then a comm_peer is created with status granted_by_user = false
      peer_ids = params[:grant][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_ids[0].each do |peer_id|
        peer = User.find peer_id
        if @user.grant_to_follow(peer)
          @subscription_granted << peer
        # comm_peer = @user.comm_port.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        # unless comm_peer.present? && comm_peer.granted_by_user
        #   if comm_peer.present?
        #     comm_peer.update_attribute(:granted_by_user, true)
        #   else
        #     comm_peer = @user.comm_port.comm_peers.create peer: User.find(peer_id), :granted_by_user, true
        #   end
        #  peer_sys_channel_enc_key = comm_peer.peer.comm_port.sys_channel_enc_key
          peer_sys_channel_enc_key = peer.comm_port.sys_channel_enc_key
          # notify peer that his subscription-request is granted from @user
          #msg = { type: :subscription_granted, peer: { id: @user.id, username: @user.username, channel_enc_key:  @user.comm_port.channel_enc_key } }
          msg = { type: :subscription_granted, peer: peer_json(@user.comm_port, { i_follow: true }) }
          add_foto_to_msg @user, msg
          #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
        end
      end
      peer_ids[1].each do |peer_id|
        comm_peer = @user.comm_port.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          if comm_peer.granted_by_user
            @subscription_grant_revoked << comm_peer.peer
            # collect message-data before destroy
            peer_sys_channel_enc_key = comm_peer.peer.comm_port.sys_channel_enc_key
            msg = { type: :subscription_grant_revoked, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_port.channel_enc_key } }
            add_foto_to_msg @user, msg
            comm_peer.destroy 
            # notify peer that his subscription-grant is revoked by @user
            #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
            comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
          end
        end
      end
    end
    if params[:deny].present?
      peer_ids = params[:deny][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      # only delete request if deny is set to true
      peer_ids[0].each do |peer_id|
        # comm_peer expected
        comm_peer = @user.comm_port.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          @subscription_denied << comm_peer.peer
          comm_peer.destroy
          # notify peer that his subscription-request is denied
          peer_sys_channel_enc_key = comm_peer.peer.comm_port.sys_channel_enc_key
          msg = { type: :subscription_denied, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_port.channel_enc_key } }
          add_foto_to_msg @user, msg
          #Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          comm_adapter.publish :system, peer_sys_channel_enc_key, msg, @user
        end
      end
    end
    @user.attributes = params[:user].permit! if params[:user].present?
    @user.save

    # respond_to do |format|
    #   format.js {}
    #   format.json { render :json => msg.to_json }
    # end
  end

  def peers
    peers_json = peers_json params[:location_id].to_i

    render json: peers_json.to_json
  end

  def delete_details
    if current_user.present?
      if params[:detail].present?
        user_json = {id:current_user.id}
        case params[:detail]
        when 'notes'
          if params[:peer_id].present?
            comm_peer = CommPeer.where(peer_id: current_user.id).first
            comm_peer.update_attribute(:note_follower, nil) if comm_peer.present?
            user_json[:note] = {id: comm_peer.comm_port.user.id}
          else
            location = Location.find(params[:location_id])
            locations_user = current_user.locations_users.where(location_id: location.id).first
            locations_user.destroy if locations_user.present?
            user_json[:note] = {id: location.id, lat: location.latitude, lng:location.longitude, address:shorten_address(location)}
          end
        end
        render json: user_json.to_json
        return
      end
    end
    render json: {message: "no action taken"}.to_json
  end

  def change_details
    if current_user.present?
      if params[:detail].present?
        user_json = {id:current_user.id}
        case params[:detail]
        when 'home_base'
          location = Location.new(latitude: params[:lat], longitude: params[:lng])
          location = nearby_location location, 5
          current_user.update_attribute :home_base, location
          user_json[:home_base] = {id: location.id, lat: location.latitude, lng:location.longitude, address:shorten_address(location)}
        when 'locations'
          #location = Location.new(latitude: params[:lat], longitude: params[:lng])
          #poi = nearby_poi(current_user, location, 10)
          #location = poi.location
          location = nearby_location Location.new(latitude: params[:lat], longitude: params[:lng]), 5
          location = current_user.locations_users.create(location: location, note: params[:text]).location unless current_user.locations_users.find{|l_u|l_u.location==location}.present?
          user_json[:last_location] = {id: location.id, lat: location.latitude, lng:location.longitude, address:shorten_address(location, true)}
        when 'notes'
          if params[:peer_id].present?
            comm_peer = CommPeer.where(peer_id: current_user.id).first
            comm_peer.update_attribute(:note_follower, params[:text]) if comm_peer.present?
            user_json[:note] = {id: comm_peer.comm_port.user.id}
          else
            location = Location.find(params[:location_id])
            locations_user = current_user.locations_users.where(location_id: location.id).first
            if locations_user.present?
              locations_user.update_attributes note: params[:text], updated_at: DateTime.now
            else
              locations_user = current_user.locations_users.create(location: location, note: params[:text])
            end
            user_json[:note] = {id: location.id, lat: location.latitude, lng:location.longitude, address:shorten_address(location)}
          end
        when 'foto'
          #current_user.update_attributes params.require(:user).permit!
          current_user.update_attribute :foto, params[:foto]
          #current_user.save
          render template: '/users/changed_details', layout: false
          return
        when 'foto_base64'
          attachment_mapping = Upload.get_attachment_mapping params[:foto_content_type]
          if attachment_mapping.size >= 2
            file_name = "#{current_user.username}.#{attachment_mapping[1]}" 
          else
            suffix = ".#{params[:foto_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
            file_name = "#{current_user.username}#{suffix}" 
          end
          current_user.set_base64_file params[:foto_data], attachment_mapping[0], file_name
          if current_user.save
            if attachment_mapping.size >= 2
              # restore original content-type after imagemagick did it's job
              suffix = ".#{params[:foto_content_type].match(/^[^\/]+\/([^\s;,]+)/)[1]}" rescue ''
              File.rename(current_user.foto.path, current_user.foto.path.sub(/\.[^.]+$/, suffix))
              current_user.update_attributes(foto_file_name: current_user.foto_file_name.sub(/\.[^.]+$/, suffix), foto_content_type: params[:foto_content_type])
            end
            geometry = Paperclip::Geometry.from_file(current_user.foto)
            user_json[:foto] = {url: current_user.foto.url, width: geometry.width.to_i, height: geometry.height.to_i}
          end
        when 'radar_settings'
          current_user.update_attribute :search_radius_meters, params[:search_radius_meters]
          user_json[:search_radius_meters] = params[:search_radius_meters]
        when 'edit_username'
          render "users/change_username", formats: [:js], locals: { edit: true }
          return
        when 'save_username'
          current_user.update_attribute(:username, params[:username])
          render "users/change_username", formats: [:js], locals: { edit: false }
          return
        end
        render json: user_json.to_json
        return
      else
        edit = (!params[:username].present?)
        unless edit
          current_user.update_attribute(:username, params[:username])
        end
        render "users/change_username", formats: [:js], locals: { edit: edit }
        return
      end
    end
    render "users/change_username", formats: [:js], locals: { edit: false }
  end

  protected

  # @see skip_before_action
  def any_request?
    [:update, :change_details].include? action_name.to_sym
  end

  def add_foto_to_msg user, msg
    geometry = Paperclip::Geometry.from_file(user.foto)
    msg[:peer][:foto] = {url: user.foto.url, width: geometry.width.to_i, height: geometry.height.to_i}
  end

end