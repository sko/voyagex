offlineZooms = [4,8,12,16]
zooms = [1..16]
mapOptions = {
               zooms: zooms
               zoom: 16
               subdomains: ['a']
               access_token: 'pk.eyJ1Ijoic3RlcGhhbmtvZWxsZXIiLCJhIjoiZEFHdnhwayJ9.AdtZiG5HGi5JAb64G1K-jA'
               max_zoom: 30
             }
new VoyageX.Main(mapOptions, offlineZooms, true) 
