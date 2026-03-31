/**
 * Created by dawid on 12.06.2023.
 * Updated by Samiirah Aujub on 09.12.2025 - COCONV 2125
 */

trigger Capitec_ContentVersionTrigger on ContentVersion (before insert, after insert) {
    new Capitec_ContentVersionTRH().run();
}