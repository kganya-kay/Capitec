/**
 * @description       : Test class for Capitec_ConversionCreateNote.cls
 * @author            : Samiirah.A@bsky.co.za
 * @group             : 
 * @last modified on  : 08-15-2025
 * @last modified by  : Samiirah.A@bsky.co.za
**/
@isTest
public with sharing class Capitec_ConversionCreateNoteTest {
    public static Id CONVERSIONS_RECORDID = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Conversions').getRecordTypeId();

    @isTest
    static void testCreateNoteFromFlow() {
        List<Capitec_ConversionCreateNote.createNoteInput> noteInputs = new List<Capitec_ConversionCreateNote.createNoteInput>();

        Case caseRecord = new Case(Subject = 'Test Case',
                                 Status = 'In Progress',
                                 Origin = 'Branch',
                                 RecordTypeId = CONVERSIONS_RECORDID
                                );

        insert caseRecord;

        Capitec_ConversionCreateNote.createNoteInput input = new Capitec_ConversionCreateNote.createNoteInput();
        input.caseId = caseRecord.Id;
        input.noteBody = 'This is a test note body';
        noteInputs.add(input);

        Test.startTest();
            Capitec_ConversionCreateNote.createNoteFromFlow(noteInputs);
        Test.stopTest();

        List<ContentDocumentLink> links = [
                                            SELECT Id, ContentDocumentId, LinkedEntityId, ShareType, Visibility
                                            FROM ContentDocumentLink
                                            WHERE LinkedEntityId = :caseRecord.Id
                                          ];
        System.assertEquals(1, links.size(), 'Should have exactly one link');

        List<ContentNote> notes = [SELECT Id, Title, Content
                                   FROM ContentNote
                                   WHERE Id = :links[0].ContentDocumentId];
                                   
        System.assertEquals(1, notes.size(), 'Should have exactly one note');
        System.assertEquals('Note', notes[0].Title, 'Note title should match');
        System.assert(notes[0].Content != null, 'Note content should not be null');

        System.assertEquals('V', links[0].ShareType, 'ShareType should be V');
        System.assertEquals('InternalUsers', links[0].Visibility, 'Visibility should be InternalUsers');
    }
}