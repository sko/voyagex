module SandboxHelper
  include ApplicationHelper
  
  def shorten_address address
    parts = address.split(',')
    if parts.size >= 3
      parts.drop([parts.size - 2, 2].min).join(',')
    else
      address
    end
  end
  
  def comment_attachment_to_view poi_note
    upload_entity_to_view poi_note.attachment
  end

  def upload_entity_to_view upload
    if upload.entity is_a? UploadEntity::Mediafile
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
    else
      'unable to display entity'
    end
  end

end
