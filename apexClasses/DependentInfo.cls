public class DependentInfo {
    public Integer size {get;set;} 
	public Integer totalSize {get;set;} 
	public Boolean done {get;set;} 
	public Object queryLocator {get;set;} 
	public String entityTypeName {get;set;} 
	public List<Record> records {get;set;} 
    public class Attributes {
		public String type_Z {get;set;} // in json: type
		public String url {get;set;} 
    }
    public class Record {
		public String MetadataComponentId {get;set;} 
        @AuraEnabled
		public String MetadataComponentName {get;set;} 
		public String RefMetadataComponentName {get;set;} 
		public String RefMetadataComponentId {get;set;} 
        @AuraEnabled
        public String MetadataComponentType {get;set;} 
    } 
    
    public static DependentInfo parse(String json){
        return (DependentInfo) System.JSON.deserialize(json, DependentInfo.class);
    }	
}