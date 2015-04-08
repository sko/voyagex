class Commit < ActiveRecord::Base
  belongs_to :user

  scope :latest, -> () { order('timestamp desc').limit(1).first }
  
  # http://stackoverflow.com/questions/552659/assigning-git-sha1s-without-git
  # "blob " + filesize + "\0" + data
  def generate_hash dataJSON
    # Poi.first.as_json  a
    data = dataJSON.to_s
    Digest::SHA1.new << "blob #{data.size}\0#{data}"
  end

end
