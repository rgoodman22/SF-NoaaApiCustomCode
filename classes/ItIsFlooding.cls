public class ItIsFlooding {
    
    //called in trigger when flood level > 2
    //MAKE EVERYTHING IN THE CONSTRUCTOR, AND THEN CALL
    
    public static map<String, Decimal> peakTides =  HighTide.populate();
    public static List<Flood__c> curFlood = new List<Flood__c>();
    public static Flood__c create_flood(Water_Reading__c wr) {
        ItIsFlooding.curFlood = [SELECT AverageStormSurge__c, AverageTidalSurge__c, MaxStormSurge__c, MaxTidalSurge__c,
                                  		  EndTime__c, StartTime__c, LastRead__c, FirstRead__c, WaterSensor__c
                                   FROM Flood__c
                                   WHERE WaterSensor__c =: wr.WaterSensor__c AND EndTime__c >: wr.DateTime__c.addHours(-6)
                                   LIMIT 1];
        
        
        if (IsNew()) {
            return NewFlood(wr);
        } else {
            system.debug(curflood[0]);
            return UpdateFlood(wr);}
        
        
        
    }
    public static boolean IsNew() {
        if (ItIsFlooding.curFlood.isEmpty()) {
            return True;
        } else {return False;}
    }
    
    public static Flood__c NewFlood(Water_Reading__c wr) {
        Flood__c f = new Flood__c(
            
            AverageStormSurge__c = wr.Storm_Surge__c,
            AverageTidalSurge__c = wr.Preliminary_Height__c,
            MaxStormSurge__c = wr.Storm_Surge__c,
            MaxTidalSurge__c = wr.Preliminary_Height__c,
            EndTime__c = wr.DateTime__c,
            StartTime__c = wr.DateTime__c,
            LastRead__c = wr.Id,
            FirstRead__c = wr.Id,
            WaterSensor__c = wr.WaterSensor__c);
        
        return f;
    }
    
    public static Flood__c UpdateFlood(Water_Reading__c wr) {
        Flood__c curFlood = ItIsFlooding.curFlood[0];
        List<Water_Reading__c> floodReads = [SELECT Preliminary_Height__c, Storm_Surge__c, WaterSensor__c, DateTime__c, WaterSensor__r.Name
                                             FROM Water_Reading__c
                                             WHERE WaterSensor__c =: curFlood.WaterSensor__c
                                             AND DateTime__c >: curFlood.StartTime__c];
        decimal sumStorm = 0;
        decimal sumTidal = 0;
        decimal maxStorm = 0;
        decimal maxTidal = 0;
        decimal avgStorm = 0;
        decimal avgTidal = 0;
        for (Water_Reading__c fr : floodReads) {
            sumStorm += fr.Storm_Surge__c;
            sumTidal += fr.Preliminary_Height__c;
            
            if (fr.Storm_Surge__c > maxStorm) {
                maxStorm = fr.Storm_Surge__c;
            } if (fr.Preliminary_Height__c> maxTidal) {
                maxTidal = fr.Preliminary_Height__c;
            }            
        }
        
        curFlood.AverageStormSurge__c = sumStorm/floodReads.size();
        curFlood.AverageTidalSurge__c = sumTidal/floodReads.size();
        curFlood.MaxStormSurge__c = maxStorm;
        curFlood.MaxTidalSurge__c = maxTidal;
        curFlood.EndTime__c = wr.DateTime__c;
        curFlood.LastRead__c = wr.Id;
        
        return curFlood;
    }
}