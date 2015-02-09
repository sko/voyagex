window.pingKey = <%= params[:key] %>
setTimeout "Comm.Comm.instance().pingBackend()", 5000
