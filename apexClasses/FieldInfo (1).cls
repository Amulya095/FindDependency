public class FieldInfo{
    public Integer size {get;set;} 
	public Integer totalSize {get;set;} 
	public Boolean done {get;set;} 
    public String nextRecordsUrl {get;set;}
	public String queryLocator {get;set;} 
	public String entityTypeName {get;set;} 
	public List<Record> records {get;set;} 
    public class Attributes {
		public String type_Z {get;set;} // in json: type
		public String url {get;set;} 
    }
    public class Record {
        @AuraEnabled
        public String Status{get;set;}
        @AuraEnabled
		public String TableEnumOrId {get;set;} 
		@AuraEnabled
		public String DeveloperName {get;set;} 
        @AuraEnabled
        public String Id{get;set;}
        @AuraEnabled
        public String Name{get;set;}
    } 
    
    public static FieldInfo parse(String json){
        system.debug('printed json = ' +json);
        return (FieldInfo) System.JSON.deserialize(json, FieldInfo.class);
    }	
}