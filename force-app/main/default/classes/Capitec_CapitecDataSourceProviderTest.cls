/**
 * Created by dawid on 20.04.2023.
 */

@IsTest
public with sharing class Capitec_CapitecDataSourceProviderTest {
    
    @IsTest
    static void testProvider(){
        capitec_CapitecDataSourceProvider provider = new capitec_CapitecDataSourceProvider();
        provider.getAuthenticationCapabilities();
        provider.getConnection(new DataSource.ConnectionParams());
    }
}