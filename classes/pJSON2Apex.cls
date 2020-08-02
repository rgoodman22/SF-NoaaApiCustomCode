public class pJSON2Apex {

	public List<Predictions> predictions;

	public class Predictions {
		public String t;
		public String v;
	}

	
	public static pJSON2Apex parse(String json) {
		return (pJSON2Apex) System.JSON.deserialize(json, pJSON2Apex.class);
	}
}