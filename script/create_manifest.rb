v_x_css = ['application', 'main']
v_x_js = ['preload', 'application', 'comm/application']

# /assets/application-c7d2632f04e910c0f7317cf6900cd9ab.css
# /assets/sandbox-ab7490470c448acc3a930ad5f8a6e76c.css
# /assets/preload-0f0eadbff248f3af34f3724c7bb2508f.js
# /assets/comm/application-ba9d765f084d296d89f375a71592327a.js
# /assets/application-4619e9ba5cb3b353952e1ae17ecaace3.js
# /assets/sandbox-88e4d654dd281276e02f40f3db6c7609.js

cache_entry_file = 'app/views/main/cache_entries.txt'
`rm #{cache_entry_file}`

find_media_cmd = "grep -oR \"[^ '\\\"]\\\\+\\\\.\\\\(png\\\\|gif\\\\|jpe\\\\?g\\\\|mp3\\\\|mpeg\\\\)\" app/ | sed \"s/^.\\\\+://\" | sed \"s/^\\\/.\\\\+//\" | grep \"[a-zA-Z0-9]\" | sort"
#find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^.+\/{{name}}-[^-]+\.{{suffix}}\""
find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public\/assets\/{{name}}-[^-]+\.{{suffix}}\""
uniq_css_paths = []
uniq_js_paths = []
uniq_media_paths = []
#puts "find_media_cmd = #{find_media_cmd}"
# find voyagex assets
puts "# voyagex assets"
`echo "# voyagex assets" >> #{cache_entry_file}`
v_x_css.each_with_index do |name, idx|
  suffix = 'css'
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  #puts "asset = #{asset}"
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_css_paths.include? uniq_path
    #puts "asset = #{asset}"
    #puts "uniq_path = #{uniq_path}"
    uniq_css_paths << uniq_path
    #puts "#{asset.gsub(/^public/, '').split.first.strip}"
    `echo "#{asset.gsub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.gsub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
v_x_js.each_with_index do |name, idx|
  suffix = 'js'
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  #puts "asset = #{asset}"
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_js_paths.include? uniq_path
    #puts "asset = #{asset}"
    #puts "uniq_path = #{uniq_path}"
    uniq_js_paths << uniq_path
    #puts "#{asset.gsub(/^public/, '').split.first.strip}"
    `echo "#{asset.gsub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.gsub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
`#{find_media_cmd}`.split.each_with_index do |entry, idx|
  name = entry.sub(/\.[a-zA-Z]+$/, '') 
  suffix = entry.sub(/^.+\.([a-zA-Z]+)$/, '\\1')
  asset = `#{find_asset_cmd.sub(/\{\{name\}\}/, name).sub(/\{\{suffix\}\}/, suffix)}`
  if asset != ''
    uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
    #uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').strip
    next if uniq_media_paths.include? uniq_path
    #puts "uniq_path = #{uniq_path}"
    uniq_media_paths << uniq_path
    #puts "#{asset.sub(/^public/, '').split.first.strip}"
    `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
    #`echo "#{asset.sub(/^public/, '').strip}" >> #{cache_entry_file}`
  end
end
# find 3rd-party assets
puts "# 3rd-party assets"
`echo "# 3rd-party assets" >> #{cache_entry_file}`
# find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.css\" | sort"
# `#{find_asset_cmd}`.split.each_with_index do |asset, idx|
#   uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
#   next if uniq_css_paths.include? uniq_path
#   #puts "uniq_path = #{uniq_path}"
#   uniq_css_paths << uniq_path
#   #puts "#{asset.sub(/^public/, '').split.first.strip}"
#   `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
# end
# find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.js\" | sort"
# `#{find_asset_cmd}`.split.each_with_index do |asset, idx|
#   uniq_path = asset.gsub(/^(.+\/.+?)-[^\/-]+$/, '\\1').split.first.strip
#   next if uniq_js_paths.include? uniq_path
#   #puts "uniq_path = #{uniq_path}"
#   uniq_js_paths << uniq_path
#   #puts "#{asset.sub(/^public/, '').split.first.strip}"
#   `echo "#{asset.sub(/^public/, '').split.first.strip}" >> #{cache_entry_file}`
# end
# only media from subdirectories - @see regexp
find_asset_cmd = "find public/assets -regextype posix-extended -regex \"^public/assets/.+/.+\\.(png|gif|jpe?g|mp3|mpeg)\" | sort"
`#{find_asset_cmd}`.split.each_with_index do |asset, idx|
  #puts "#{asset.sub(/^public/, '').strip}"
  `echo "#{asset.sub(/^public/, '').strip}" >> #{cache_entry_file}`
end
