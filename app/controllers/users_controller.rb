class UsersController < ApplicationController 

  def update
    @user = User.find(params[:id])
    @subscribe = []
    @un_subscribe = []
    if params[:follow].present?
      # "follow"=>{"comm_peer_settings"=>{"3"=>"false", "2"=>"true", "4"=>"false"}}
      peer_setting_ids = params[:follow][:comm_peer_settings].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_setting_ids[0].each do |peer_setting_id|
        peer_setting = CommSetting.find peer_setting_id
        if peer_setting.comm_peers.find{|c_p|c_p.peer_id==@user.id}
          @subscribe << peer_setting.channel_enc_key
        else
          peer_setting.comm_peers.create(peer_id: @user.id)
        end
      end
      peer_setting_ids[1].each do |peer_setting_id|
        peer_setting = CommSetting.find peer_setting_id
        comm_peer = peer_setting.comm_peers.find{|c_p|c_p.peer_id==@user.id}
        if comm_peer.present?
          comm_peer.destroy 
          @un_subscribe << peer_setting.channel_enc_key
        end
      end
    end
    if params[:grant].present?
      peer_ids = params[:grant][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_ids[0].each do |peer_id|
        # comm_peer expected
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        comm_peer.update_attribute(:granted_by_peer, true)
      end
      peer_ids[1].each do |peer_id|
        # comm_peer expected
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          # only delete granted, keep requests for decision
          comm_peer.destroy if comm_peer.granted_by_peer == true
        end
      end
    end
    if params[:deny].present?
      peer_ids = params[:deny][:comm_peers].inject([[],[]]){|res,kv|kv[1]=='true'?res[0]<<kv[0]:res[1]<<kv[0];res}
      peer_ids[1].each do |peer_id|
        # comm_peer expected
        comm_peer = @user.comm_setting.comm_peers.find{|c_p|c_p.peer_id==peer_id.to_i}
        if comm_peer.present?
          # only delete granted, keep requests for decision
          comm_peer.destroy if comm_peer.granted_by_peer == true
        end
      end
    end
    @user.attributes = params[:user].permit!
    @user.save
  end

  def change_details
    if current_user.present?
      edit = (!params[:username].present?)
      unless edit
        current_user.update_attribute(:username, params[:username])
      end
      render "users/change_username", formats: [:js], locals: { edit: edit }
      return
    end
    render "users/change_username", formats: [:js], locals: { edit: false }
  end

end