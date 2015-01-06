class UploadEntity::Embed < ActiveRecord::Base
  self.table_name = 'upload_entities_embeds'
  
  #belongs_to :upload, inverse_of: :entity
  belongs_to :upload, inverse_of: :embed

  def self.get_embed_type text
    if text.match(/^</).present?
      # youtube, ...
    else
      suffixMatch = text.match(/[^.]+$/)
      if suffixMatch.present?
        if ['jpg','jpeg','gif','png','webp'].include?(suffixMatch[0])
          return "image/#{suffixMatch[0]}"
        else
        end
      end
    end
    nil
  end
end
