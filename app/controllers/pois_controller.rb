class PoisController < ApplicationController 
  include GeoUtils
  include ApplicationHelper
  include PoiHelper

  #
  # FIXME there's a problem with csrf from app-cache (after updating version) - 
  #       no current_user will be set then.
  #
  #skip_before_filter :verify_authenticity_token, only: [:create, :update]
  skip_before_action :verify_authenticity_token, if: :current_user_required?

  def index
    render layout: 'uploads'
  end

  #
  # TODO: 
  # +) comment-on
  #
  # sync pois that where edited offline
  def pull_pois
    @user = tmp_user
    if ![:development].include?(Rails.env.to_sym)# || true
      Resque.enqueue(PostCommit, {action: 'pull_pois',
                                  user_id: @user.id,
                                  commit_hash: params[:commit_hash]})
    else
      PostCommit.new.pull_pois @user.id,
                               params[:commit_hash],
                               false
    end
    render json: { message: 'OK' }.to_json
  end

  #
  # TODO: 
  # +) comment-on
  #
  # sync pois that where edited offline
  def sync_poi
    @user = tmp_user
    # required for providing user to poi_notes
    commit = @user.commits.create hash_id: DateTime.now.to_s, timestamp: DateTime.now#, local_time_secs: 
    errors = []
    poi_jsons = []
    min_local_time_secs_list = []
    params[:poi_ids].each do |poi_id|
      if poi_id.to_i >= 0
        poi = Poi.find poi_id
        # if poi is meanwhile deleted by other user then create new one - tell user to replace old ...
      else
        poi = nearby_poi @user, Location.new(latitude: params[:location][poi_id.to_s][:latitude], longitude: params[:location][poi_id.to_s][:longitude])
        poi.commit = commit unless poi.commit.present?
        poi.location.commit = commit unless poi.location.commit.present?
      end
      @user.locations << poi.location unless @user.locations.find {|l|l.id==poi.location.id}
      is_new_poi = poi.notes.empty?

      new_poi_notes = []
      min_local_time_secs = -1
      params[:poi_note_ids][poi_id.to_s].each do |poi_note_id|
        poi_note_local_time_secs = poi_note_id.to_i.abs # (poi_note_id.to_i/1000).round.abs
        min_local_time_secs = poi_note_local_time_secs if (min_local_time_secs == -1) || (poi_note_local_time_secs < min_local_time_secs)

        file = params[:poi_note][poi_id.to_s][poi_note_id][:file]
        if file.present? || (embed = params[:poi_note][poi_id.to_s][poi_note_id][:embed]).present?
          upload = Upload.new(attached_to: PoiNote.new(poi: poi, commit: commit, text: params[:poi_note][poi_id.to_s][poi_note_id][:text], local_time_secs: poi_note_local_time_secs))
          upload.attached_to.attachment = upload
          if file.present?
            upload.build_entity file.content_type, file: file
          else
            upload.build_entity :embed, text: embed[:content], embed_type: UploadEntity::Embed.get_embed_type(embed[:content])
          end
          poi_note = upload.attached_to
        else
          poi_note = PoiNote.new(poi: poi, commit: commit, text: params[:poi_note][poi_id.to_s][poi_note_id][:text], local_time_secs: poi_note_local_time_secs)
        end
        poi.notes << poi_note
        new_poi_notes << poi_note
      end
      poi.local_time_secs = min_local_time_secs if is_new_poi
      
      if poi.save
        note_json_list = new_poi_notes.collect{|note| poi_note_json(note, false).
                                                      merge({local_time_secs: note.local_time_secs}) }
        poi_json = poi_json(poi).
                   merge(is_new_poi && poi.user==@user ? {local_time_secs: poi.local_time_secs} : {}).
                   merge(user: { id: @user.id }).
                   merge(notes: note_json_list)
        poi_jsons << poi_json
        min_local_time_secs_list << min_local_time_secs
      else
        errors << poi.errors.full_messages
      end
    end
    commit.update_attribute :local_time_secs, min_local_time_secs_list.min

    if ![:development].include?(Rails.env.to_sym)# || true
      Resque.enqueue(PostCommit, {action: 'sync_pois',
                                  commit_id: commit.id,
                                  poi_ids: params[:poi_ids],
                                  min_local_time_secs_list: min_local_time_secs_list})
    else
      PostCommit.new.sync_pois commit.id,
                               params[:poi_ids],
                               min_local_time_secs_list,
                               false
    end

    render json: { pois: poi_jsons, errors: errors }.to_json
  end

  # @deprecated - sync_poi is used by client after saving data first locally
  def destroy
    # TODO don't delete if first poiNote - can only be deleted via poi
    @poi = Poi.find(params[:id])
    @poi.destroy
    if ![:development].include?(Rails.env.to_sym)# || true
      Resque.enqueue(PostCommit, {action: 'delete_poi',
                                  user_id: current_user.id,
                                  poi_id: params[:id]})
    else
      PostCommit.new.delete_poi current_user.id,
                                params[:id],
                                false
    end
    render json: { message: 'OK' }.to_json
  end

  # api
  def pois
    user = current_user || tmp_user

    pois_json = []
    @pois = nearby_pois Location.new(latitude: params[:lat], longitude: params[:lng]), (user.search_radius_meters||1000)
    @pois.each do |poi|
      pois_json << poi_json(poi)
    end
    
    render json: pois_json.to_json
  end

  # api
  def comments
    user = current_user || tmp_user
    if params[:poi_note_id] != '-1'
      poi_note = PoiNote.find(params[:poi_note_id])
      poi = poi_note.poi
    else
      poi_note = nil
      poi = Poi.find(params[:poi_id]) if params[:poi_id].present?
    end

    poi_json = poi_json poi
    poi_json[:notes] = poi_notes_as_list poi, poi_note

    render json: {poi: poi_json}.to_json
  end

  def csrf
    render "shared/csrf", layout: 'uploads'
  end

  protected

  # @see skip_before_action
  def current_user_required?
    [:pull_pois, :sync_poi, :destroy, :pois, :comments].include? action_name.to_sym
  end

end
