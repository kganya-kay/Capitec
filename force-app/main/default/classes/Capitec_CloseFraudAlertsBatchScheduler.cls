/**
 * Created by CalebGovender on 2024/11/07.
 */
public class Capitec_CloseFraudAlertsBatchScheduler implements Schedulable {
    public void execute(SchedulableContext SC) {
        Capitec_CloseFraudAlertsBatch batch = new Capitec_CloseFraudAlertsBatch();
        Database.executeBatch(batch, 200); // 200 is the batch size
    }
}