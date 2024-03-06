public class HttpCallout {
    
    public static String restGet(String endPoint, String method) {
        try
        {
            PageReference newPage = Page.SessionDetails;
            String content = newPage.getContent().toString();
            // W-006256 - commented system debug system.debug(' content '+content);
            // W-006256 - commented system debug system.debug(content.indexOf('Session_Id_Start') +' >> '+ content.indexOf('Session_Id_End') );
            Integer s = content.indexOf('Session_Id_Start') + 'Session_Id_Start'.length();
            Integer e = content.indexOf('Session_Id_End');
            string sessionId = content.substring(s, e);
            
            
            Http h = new Http();
            HttpRequest hr = new HttpRequest();
            hr.setHeader('Authorization', 'Bearer ' + sessionId);
            hr.setTimeout(60000);
            hr.setEndpoint(endPoint);
            hr.setMethod(method);
            HttpResponse r = h.send(hr);
			system.debug(r);           
            return r.getBody();
        }
        catch(Exception ex)
        {
            system.debug('Exception in tooling API Call:'+ ex.getMessage());
            return ex.getMessage();
        }
    }
}