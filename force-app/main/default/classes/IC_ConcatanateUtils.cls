public class IC_ConcatanateUtils {
    
            @InvocableMethod(label='Required Document Type' description='Concatanates the selected required document types into a string')
            public static List<documentTypeResponse> concatanateDocumentTypes(List<documentTypeRequest> requests) {    
            List<documentTypeResponse> responses = new List<documentTypeResponse>();  
                
            for (documentTypeRequest request : requests) {
            String documentType = request.documentType;
            
            
            documentTypeResponse response = new documentTypeResponse();
            response.documentType = String.valueOf(documentType).replace(';', ',');
            responses.add(response);
            system.debug(response);                
        }
        system.debug(responses);
        
        return responses;
    }
    
        // Inner class to hold input variables
    public class documentTypeRequest {
        @InvocableVariable(required=true)
        public String documentType;
    }

    public class documentTypeResponse {
        @InvocableVariable(required=true)
        public String documentType;
    }
    
}