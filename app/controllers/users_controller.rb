class UsersController < ApplicationController 
  include GeoUtils

  def update
    @user = User.find(params[:id])
    # there's no subscribe here because @user would need grant first. he could try anyway - TODO?
    @un_subscribe = []
    if params[:follow].present?
      peer_setting_ids = params[:follow][:comm_peer_settings].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_setting_ids[0].each do |peer_setting_id|
        peer_setting = CommSetting.find peer_setting_id
        unless peer_setting.comm_peers.find{|c_p|c_p.peer_id==@user.id}
          peer_setting.comm_peers.create(peer_id: @user.id)
          # notify peer that @user requests subscription-grant
          peer_sys_channel_enc_key = peer_setting.sys_channel_enc_key
          msg = { type: :subscription_grant_request, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_setting.channel_enc_key } }
          Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
        end
      end
      peer_setting_ids[1].each do |peer_setting_id|
        peer_setting = CommSetting.find peer_setting_id
        comm_peer = peer_setting.comm_peers.find{|c_p|c_p.peer_id==@user.id}
        if comm_peer.present?
          comm_peer.destroy
          if comm_peer.granted_by_peer
            @un_subscribe << peer_setting.channel_enc_key 
            # notify peer that @user does not follow anymore
            peer_sys_channel_enc_key = peer_setting.sys_channel_enc_key
            msg = { type: :quit_subscription, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_setting.channel_enc_key } }
            Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          #else
          #  # notify peer that @user does not request grant anymore
          #  peer_sys_channel_enc_key = peer_setting.sys_channel_enc_key
          #  msg = { type: :cancel_subscription_grant_request, peer: { id: @user.id, username: @user.username, channel_enc_key: @user.comm_setting.channel_enc_key } }
          #  Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          end
        end
      end
    end
    if params[:grant].present?
      # comm_peer expected 
      # when a peer requests a grant then a comm_peer is created with status granted_by_peer = false
      peer_ids = params[:grant][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_ids[0].each do |peer_id|
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        unless comm_peer.granted_by_peer
          comm_peer.update_attribute(:granted_by_peer, true)
          # notify peer that his subscription-request is granted from @user
          peer_sys_channel_enc_key = comm_peer.peer.comm_setting.sys_channel_enc_key
          msg = { type: :subscription_granted, peer: { comm_setting_id: @user.comm_setting.id, username: @user.username, channel_enc_key:  @user.comm_setting.channel_enc_key } }
          Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
        end
      end
      peer_ids[1].each do |peer_id|
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          if comm_peer.granted_by_peer
            # collect message-data before destroy
            peer_sys_channel_enc_key = comm_peer.peer.comm_setting.sys_channel_enc_key
            msg = { type: :subscription_grant_revoked, peer: { comm_setting_id: @user.comm_setting.id, username: @user.username, channel_enc_key: @user.comm_setting.channel_enc_key } }
            comm_peer.destroy 
            # notify peer that his subscription-grant is revoked by @user
            Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
          end
        end
      end
    end
    if params[:deny].present?
      peer_ids = params[:deny][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      # only delete request if deny is set to true
      peer_ids[0].each do |peer_id|
        # comm_peer expected
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          comm_peer.destroy
          # notify peer that his subscription-request is denied
          peer_sys_channel_enc_key = comm_peer.peer.comm_setting.sys_channel_enc_key
          msg = { type: :subscription_denied, peer: { comm_setting_id: @user.comm_setting.id, username: @user.username, channel_enc_key: @user.comm_setting.channel_enc_key } }
          Comm::ChannelsController.publish("/system#{PEER_CHANNEL_PREFIX}#{peer_sys_channel_enc_key}", msg)
        end
      end
    end
    @user.attributes = params[:user].permit!
    @user.save
  end

  def change_details
    if current_user.present?
      if params[:detail].present?
        user_json = {}
        case params[:detail]
        when 'home_base'
          location = Location.new(latitude: params[:lat], longitude: params[:lng])
          location = nearby_location location, 5
          current_user.update_attribute :home_base, location
          user_json[:id] = current_user.id
          user_json[:home_base] = {id: location.id, lat: location.latitude, lng:location.longitude, address:location.address}
        when 'locations'
          location = Location.new(latitude: params[:lat], longitude: params[:lng])
          location = nearby_poi(current_user, location, 10).location
          user_json[:id] = current_user.id
          user_json[:last_location] = {id: location.id, lat: location.latitude, lng:location.longitude, address:location.address}
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

end