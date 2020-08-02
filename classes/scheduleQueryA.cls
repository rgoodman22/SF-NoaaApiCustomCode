global class scheduleQueryA implements Schedulable, database.allowscallouts{
    public void execute(SchedulableContext ctx) {
        NOAAQuery.pushEvents(0);
    }
}