module SandboxHelper
  include ::ApplicationHelper
  include ::GeoUtils
  
  def comment_attachment_to_view poi_note
    upload_entity_to_view poi_note.attachment
  end

  def upload_entity_to_view upload
    if upload.entity.is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        max_width = 100
        image_tag upload.entity.file.url, style: "width:#{max_width.to_i}px;" 
      when 'audio'
        content_tag(:audio, upload.entity.id.to_s, controls: 'controls') do
          inner_html = content_tag :source, nil, src: upload.entity.file.url, type: upload.entity.file.content_type
          inner_html += 'Your browser does not support the audio element.'
          inner_html
        end
      when 'video'
        content_tag(:video, upload.entity.id.to_s, controls: 'controls') do
          inner_html = content_tag :source, nil, src: upload.entity.file.url, type: upload.entity.file.content_type
          inner_html += 'Your browser does not support the video element.'
          inner_html
        end
      else
        "unable to display entity with content_type: #{upload.entity.content_type}"
      end
    elsif upload.entity.is_a? UploadEntity::Embed
      case upload.entity.embed_type.match(/^[^\/]+/)[0]
      when 'image' 
        max_width = 100
        image_tag upload.entity.text, style: "width:#{max_width.to_i}px;" 
      else
        "unable to display entity with content_type: #{upload.entity.content_type}"
      end
    else
      'unable to display entity'
    end
  end

  def upload_entity_preview_url upload
    if upload.entity.is_a? UploadEntity::Mediafile
      case upload.entity.content_type.match(/^[^\/]+/)[0]
      when 'image' 
        upload.file.url
      when 'audio'
        '/assets/audio-file.png'
      when 'video'
        '/assets/video-file.png'
      else
        '/assets/no-preview.png'
      end
    elsif upload.entity.is_a? UploadEntity::Embed
      case upload.entity.embed_type.match(/^[^\/]+/)[0]
      when 'image' 
        upload.entity.text
      else
        '/assets/no-preview.png'
      end
    else
      '/assets/no-preview.png'
    end
  end

  def peer_json c_p
    last_loc = c_p.user.snapshot.location||nearby_location(Location.new(latitude: c_p.user.snapshot.lat, longitude: c_p.user.snapshot.lng), 10)
    last_loc_poi = last_loc.persisted? ? Poi.where(location: last_loc).first : nearby_pois(last_loc, 10).first
    geometry = Paperclip::Geometry.from_file(c_p.user.foto) if c_p.user.foto.present?
    foto_width = geometry.present? ? geometry.width.to_i : -1
    foto_height = geometry.present? ? geometry.height.to_i : -1
    "{id: #{c_p.user.id}, username: '#{c_p.user.username}', lastLocation: {id: #{last_loc.id||'null'}, lat: #{last_loc.latitude}, lng: #{last_loc.longitude}, address: '#{shorten_address(last_loc, true)}'#{last_loc_poi.present? ? ", poiId: #{last_loc_poi.id}" : ''}}, foto: {url: '#{c_p.user.foto.url}', width: #{foto_width}, height: #{foto_height}}, peerPort: {id: #{c_p.id}, channel_enc_key: '#{c_p.channel_enc_key}'}}"
  end

end
