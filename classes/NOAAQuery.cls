public class NOAAQuery {
    public static set<String> validDataType = new set<String>
        (new string[]{'air_gap','air_pressure','air_temperature','conductivity','currents',
                      'currents_survey', 'currents_predictions','daily_mean', 'datums', 'high_low',
                      'hourly_height','humidity','monthly_mean','one_minute_water_level','predictions',
                      'salinity','visibility','water_level','water_temperature','wind'});
    
    public static String  getData(string station, string dataType) {
       	//input validation
        if (station.length() != 7) {
            system.debug('Invalid station input');
        }
        
        if (!(NOAAQuery.validDataType.contains(dataType))) {
            system.debug('Invalid dataType input.');
        }
        //Creating URL for Request
        string URL = 'https://api.tidesandcurrents.noaa.gov:443/api/prod/datagetter?';
        string payload = 'date=latest' + 
            			 '&'+'station=' + station +
            			 '&'+'product=' + dataType +  
            			 '&'+'datum=MSL&units=english&time_zone=GMT&application=Salesforce&format=json';
        system.debug(payload);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setTimeout(60000);
        request.setEndpoint(URL);
        request.setMethod('GET');
        request.setBody(payload);
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        integer counter = 0;
        string returnValue = response.getBody();
        string errorContent = '"error"';
        string htmlContent = '<html>';
        integer hitRepeats = 0;
        
        
        while (counter <= hitRepeats  && (response.getStatusCode() == 504 || returnValue.contains(errorContent) || returnValue.contains(htmlContent))) {          
            //handle error
            system.debug('504 error handling...');
            system.debug(response.getHeader('Location'));
            //if we have hit the site desired number of times, pass dummy values
            if (counter == hitRepeats) {
                if (dataType == 'predictions') {
                    returnValue = '{ "predictions" : [{"t":"2020-07-20 13:06", "v":"1000.999"},{"t":"2020-07-20 13:12", "v":"1000.999"},'
                        +'{"t":"2020-07-20 13:18", "v":"1000.999"},{"t":"2020-07-20 13:24", "v":"1000.999"},'
                        +'{"t":"2020-07-20 13:30", "v":"1000.999"},{"t":"2020-07-20 13:36", "v":"1000.999"}]}';
                } else if (dataType == 'water_level') {
                    returnValue = '{"metadata":{"id":"8575512","name":"Annapolis","lat":"38.9833","lon":"-76.4816"},'
                        +'"data":[{"t":"2020-07-20 13:24", "v":"1000.999", "s":"0.013", "f":"1,0,0,0", "q":"p"}]}';}
                
            } else { // we haven't hit the site hitRepeats times, try again
                response = http.send(request);
                returnValue = response.getBody();
                
            } counter +=1; //0 on first go, 1 on second, doesn't get to a third repeat (right now)
        } 
        return returnValue;
    }
	
    public static dJSON2Apex getWaterLevel(string station) {
        string data = NOAAQuery.getData(station, 'water_level');
        dJSON2Apex desired = dJSON2Apex.parse(data);
        return desired;
    }
    
    public static pJSON2Apex getPredictions(string station) {
        string data = NOAAQuery.getData(station, 'predictions');
        pJSON2Apex desired = pJSON2Apex.parse(data);
        return desired;
    }
    
    public static Water_Level_Reading__e createEvent(string station, string sID, string name) {
        pJSON2Apex MyPredictions = NOAAQuery.getPredictions(station);
        dJSON2Apex MyData = NOAAQuery.getWaterLevel(station);
        
        if (MyPredictions.predictions[0].v == '1000.999' || MyData.data[0].v == '1000.999') {
            Water_Level_Reading__e NewEvent = new Water_Level_Reading__e(
        			DateTime__c=datetime.newInstanceGmt(0000, 00, 00, 00, 00, 0),
        			Predicted_Height__c=1000.999,
        			Preliminary_Height__c=1000.999,
        			Sensor_Id__c=station,
        			Sensor__c = sID,
        			Sensor_Name__c = name);
            return NewEvent;
        }
        
        string scurTime = MyData.data[0].t;
        datetime curTime = datetime.newInstanceGmt(integer.valueOf(scurTime.substring(0, 4)),
                                                   integer.valueOf(scurTime.substring(5, 7)),
                                                   integer.valueOf(scurTime.substring(8, 10)),
                                                   integer.valueOf(scurTime.substring(11, 13)),
                                                   integer.valueOf(scurTime.substring(14, 16)), 0);
        
        pJSON2Apex.Predictions desired;
        for (pJSON2Apex.predictions p : MyPredictions.predictions) {
            string spTime = p.t;
            datetime pTime = datetime.newInstanceGmt(integer.valueOf(spTime.substring(0, 4)),
                                                 integer.valueOf(spTime.substring(5, 7)),
                                                 integer.valueOf(spTime.substring(8, 10)),
                                                 integer.valueOf(spTime.substring(11, 13)),
                                                 integer.valueOf(spTime.substring(14, 16)), 0);
            if (pTime == curTime) {
                desired = p;
                break;
            }
        }
        // Create Platform event to push
        Water_Level_Reading__e NewEvent = new Water_Level_Reading__e(
        			DateTime__c=curTime,
        			Predicted_Height__c=decimal.valueOf(desired.v),
        			Preliminary_Height__c=decimal.valueOf(MyData.data[0].v),
        			Sensor_Id__c=station,
        			Sensor__c = sID,
        			Sensor_Name__c = name);
        
        return NewEvent;
    }
    @future(callout=true)
    public static void pushEvents(integer i) {
        //List to hold event objects
        List<Water_Level_Reading__e> events = new List<Water_Level_Reading__e>();
        
        //Query selected sensors
        List<WaterSensor__c> selectStations;
        if (i==0) {
            selectStations = [SELECT Sensor_ID__c, Name, ID FROM WaterSensor__c 
                              ORDER BY Name ASC LIMIT 33];
        } else {
            selectStations = [SELECT Sensor_ID__c, Name, ID FROM WaterSensor__c
                              ORDER BY Name DESC LIMIT 34];
        }
        system.debug(selectStations);
        
        //Add event objects to list
        for (WaterSensor__c station : selectStations) {
            Water_Level_Reading__e eventToAdd = createEvent(station.Sensor_ID__c, station.ID, station.name);
            if (eventToAdd.Predicted_Height__c == 1000.999) {
                continue;}
            events.add(eventToAdd);
            system.debug('Event created: ' + station.name);
        }
        
        //Call method to publish events.
        List<Database.SaveResult> results = EventBus.publish(events);
        
        //Inspect publishing result for each event
        for (database.SaveResult sr : results) {
            if (sr.isSuccess()) {System.debug('Successfully published event.');}
            else{
                for (Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +
                                err.getStatusCode() + 
                                ' - ' +
                                err.getMessage());
                }
            }
        }
    }
}


//push event
//	for loop
//		create event
//			dJSON2Apex
//				getData
//			pJSON2Apex
//				getData(screwing up)
