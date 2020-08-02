public class DeleteSimilarRecordsc {
    public static void byDateTime(dateTime dt) {
        List<Water_Reading__c> faultyRecords = [SELECT predicted_height__c, preliminary_height__c
                                                FROM Water_Reading__c 
                                                WHERE DateTime__c =:dt];
        
        while(True) {
            integer count = 0;
            List<Water_Reading__c> toDelete = new list<Water_Reading__c>();
            decimal prelim = 0;
            decimal predic = 0;
            
            if (faultyRecords.isEmpty()) {
                system.debug('Iteration over');
                break;
            }
            
            for (integer i=0; i<faultyrecords.size();i++) {
                Water_Reading__c r = faultyRecords[i];
                if (count == 0) {
                    count = count+1;
                    prelim = r.Preliminary_Height__c;
                    predic = r.Predicted_Height__c;
                    toDelete.add(r);
                    continue;
                } else if (string.valueOf(prelim) == string.valueOf(r.Preliminary_Height__c) 
                    && string.valueOf(predic) == string.valueOf(r.Predicted_Height__c)) {
                        count = count+1;
                        toDelete.add(r);
                        faultyRecords.remove(faultyRecords.indexOf(r));
                    }
                }
            if (count == 1) {
                faultyRecords.remove(0);
                continue;
            }
            else {
                system.debug('Deleting records:' + string.valueOf(count));
                delete toDelete;}
        }
        
    }
    public static void executeCurDelete() {
        datetime dt = datetime.newInstanceGMT(2020, 07, 20,00, 00, 0);
        for (integer k = 0; k<100; k++) {
            DeleteSimilarRecordsc.byDateTime(dt);
            dt = dt + (6/1440);
        }
    }
}