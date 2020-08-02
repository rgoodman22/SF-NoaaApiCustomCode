global class scheduleQueryB implements Schedulable, database.allowscallouts{
    public void execute(SchedulableContext ctx) {
        NOAAQuery.pushEvents(1);
    }
}