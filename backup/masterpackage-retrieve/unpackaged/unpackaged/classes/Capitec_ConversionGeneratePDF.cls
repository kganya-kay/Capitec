/**
 * @description       : Invocable Class to create PDF for a Conversion Case [COCONV-1990]
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 09-09-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Capitec_ConversionGeneratePDF {
    public class Request {
        @InvocableVariable(required=true) public Id caseId;
    }
    public class Response {
        @InvocableVariable public Boolean success;
        @InvocableVariable public String message;
        @InvocableVariable public Id contentDocumentId;
    }

    @InvocableMethod(label='Generate Debit Order PDF' description='Render DebitOrderPDF VF page and attach to Case')
    public static List<Response> generatePDF(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request request : requests) {
            Response res = new Response();
            Id caseId = request.caseId;

            System.debug('##generatePDF caseid:' + caseId);

            try {
                PageReference pageRef = Page.Switch_Request_Template;
                pageRef.getParameters().put('id', (String)caseId);
                pageRef.setRedirect(false);

                System.debug('##generatePDF pageRef:' + pageRef);


                Blob pdfBlob;
                if (Test.isRunningTest()) {
                    pdfBlob = Blob.valueOf('TEST_PDF_BYTES'); 
                } else {
                    pdfBlob = pageRef.getContentAsPDF();
                }

                System.debug('##generatePDF pdfBlob:' + pdfBlob);


                ContentVersion contentVersion = new ContentVersion();
                contentVersion.Title = 'Switch Request Template';
                contentVersion.PathOnClient = 'Switch_Request_Template.pdf';
                contentVersion.FirstPublishLocationId = caseId;
                contentVersion.VersionData = pdfBlob;
                insert contentVersion;

                System.debug('##generatePDF contentVersion:' + contentVersion);


                ContentVersion createdContentVersion = [SELECT Id, 
                                                               ContentDocumentId
                                                        FROM ContentVersion
                                                        WHERE Id = :contentVersion.Id
                                                        LIMIT 1
                                                    ];


                System.debug('##generatePDF createdContentVersion:' + createdContentVersion);



                ContentDocumentLink link = new ContentDocumentLink();
                link.ContentDocumentId = createdContentVersion.ContentDocumentId;
                link.LinkedEntityId = caseId;
                link.ShareType = 'V';
                link.Visibility = 'AllUsers';
                insert link;

                System.debug('##generatePDF link:' + link);

                // Response
                res.success = true;
                res.contentDocumentId = createdContentVersion.ContentDocumentId;
                res.message = 'PDF generated and attached.';
            } catch (Exception e) {
                res.success = false;
                res.message = e.getMessage();
            }
            results.add(res);
        }

        return results;
    }
}