@isTest
public class IC_ConcatanateUtils_TEST {

    // Positive test case
    @isTest static void testConcatanateDocumentTypes() {
        // Create a request list
        List<IC_ConcatanateUtils.documentTypeRequest> requestList = new List<IC_ConcatanateUtils.documentTypeRequest>();
        
        IC_ConcatanateUtils.documentTypeRequest request1 = new IC_ConcatanateUtils.documentTypeRequest();
        request1.documentType = 'type1;type2';
        requestList.add(request1);

        IC_ConcatanateUtils.documentTypeRequest request2 = new IC_ConcatanateUtils.documentTypeRequest();
        request2.documentType = 'type3;type4';
        requestList.add(request2);

        // Call the method
        List<IC_ConcatanateUtils.documentTypeResponse> responseList = IC_ConcatanateUtils.concatanateDocumentTypes(requestList);

        // Check the response
        System.assertEquals(2, responseList.size());
        System.assertEquals('type1,type2', responseList[0].documentType);
        System.assertEquals('type3,type4', responseList[1].documentType);
    }

    // Negative test case with empty string
    @isTest static void testConcatanateDocumentTypesWithEmptyString() {
        // Create a request list with empty string
        List<IC_ConcatanateUtils.documentTypeRequest> requestList = new List<IC_ConcatanateUtils.documentTypeRequest>();
        
        IC_ConcatanateUtils.documentTypeRequest request = new IC_ConcatanateUtils.documentTypeRequest();
        request.documentType = '';
        requestList.add(request);

        // Call the method
        List<IC_ConcatanateUtils.documentTypeResponse> responseList = IC_ConcatanateUtils.concatanateDocumentTypes(requestList);

        // Check the response
        System.assertEquals(1, responseList.size());
        System.assertEquals('', responseList[0].documentType);
    }
}