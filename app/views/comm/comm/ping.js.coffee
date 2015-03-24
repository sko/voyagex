window.pingKey = <%= params[:key] %>
setTimeout "APP.backend().pingBackend()", 5000
