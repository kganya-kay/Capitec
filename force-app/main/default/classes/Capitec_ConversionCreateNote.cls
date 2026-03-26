/**
 * @description       : Invocable Method to create Note for a Conversion Case
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 08-15-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
public with sharing class Capitec_ConversionCreateNote {

    @InvocableMethod(label='Create Note and link to case')
    public static void createNoteFromFlow(List<createNoteInput> requests) {
        List<ContentNote> lstNotesToInsert = new List<ContentNote>();
        List<ContentDocumentLink> lstContentLinks = new List<ContentDocumentLink>();

        System.debug('##Capitec_ConversionCreateNote size:'+ requests.size());
         System.debug('##Capitec_ConversionCreateNote size:'+ requests);

        for (createNoteInput req : requests) {
            if(req.noteBody != null){
                System.debug('##Capitec_ConversionCreateNote Creating NOTE');
                ContentNote note = new ContentNote();

                note.Title   = 'Note';
                note.Content = Blob.valueOf(req.noteBody != null ? req.noteBody : '');
                lstNotesToInsert.add(note);   
            }

        }

        System.debug('##lstNotesToInsert size:'+ lstNotesToInsert.size());
        insert lstNotesToInsert;

        for (Integer i = 0; i < lstNotesToInsert.size(); i++) {
            System.debug('##Capitec_ConversionCreateNote Creating LINK');
            ContentDocumentLink link = new ContentDocumentLink();

            link.ContentDocumentId = lstNotesToInsert[i].Id;
            link.LinkedEntityId = requests[i].caseId;
            link.ShareType = 'V';
            link.Visibility = 'InternalUsers';
            lstContentLinks.add(link);
        }

        insert lstContentLinks;
    }

    public class createNoteInput {
        @InvocableVariable(required=true)
        public Id caseId;

        @InvocableVariable(required=true)
        public String noteBody;
    }

}