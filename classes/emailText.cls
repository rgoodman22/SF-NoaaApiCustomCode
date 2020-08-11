public class emailText {
    public static void sendText(Flood__c fl) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        list<String> to = new list<String>();
        to.add('2024457230@txt.att.net');
        email.setToAddresses(to);
        
        String subject = 'FLOOD WARNING';
        email.setSubject(subject);
        
        String sender = 'NOAA National Weather Service';
        email.setSenderDisplayName(sender);
        
        
        string location = [SELECT Name FROM WaterSensor__c
                           WHERE Id =: fl.WaterSensor__c].Name;
        double curHeight = fl.MaxTidalSurge__c;
        decimal maxHeight = HighTide.populate().get(location);
        decimal compHeight = curHeight-maxHeight;
        string cur = string.valueOf(curHeight);
        string comp = string.valueOf(compHeight);
        string storm = string.valueOf(fl.MaxStormSurge__c);
        
        String body = 'Flooding is imminent or occuring at ' + location + '.\n' +
            		  'Current Water Level: ' + cur + ' ft. \n' +
            		  'Storm Surge: ' + storm + ' ft. \n' +
            		  'Tidal Surge: ' + comp + ' ft.';
     //'NOAA recommends that you take necessary precautions to protect your property, and then distance from the the coast.' 
        email.setHtmlBody(body);
        
        list<Messaging.SingleEmailMessage> emailList = new list<Messaging.SingleEmailMessage>();
        emailList.add(email);
        messaging.sendEmail(emailList);
    }
}
