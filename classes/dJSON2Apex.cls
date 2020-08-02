public class dJSON2Apex {
	public Metadata metadata;
	public List<Data> data;

	public class Metadata {
		public String id;
		public String name;
		public String lat;
		public String lon;
	}

	public class Data {
		public String t;
		public String v;
		public String s;
		public String f;
		public String q;
	}

	
	public static dJSON2Apex parse(String json) {
		return (dJSON2Apex) System.JSON.deserialize(json, dJSON2Apex.class);
	}
}