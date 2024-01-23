public class DependencyController {
    
   	//Retrieve All Objects in org
    @Auraenabled(cacheable=true)
    public static ObjectDetail getObjects()
    {
        List<FieldInfo.Record> objects=getCustomObject();
        List<FieldInfo.Record> fields=getObjectFields();
        // for(FieldInfo.Record fieldList: fields){
        //     if(fieldList.TableEnumOrId == '01I1Q000002ZOo7UAG')
        //         system.debug('enum id has been found congrats');
        // }
        
        ObjectDetail detail=new ObjectDetail();
        detail.Objects=objects;
        detail.Fields=fields;
        
        return detail;
    }
    
    @Auraenabled(cacheable=true)
    public static List<ApexClass> getApex()
    {
       return [Select Id,Name from ApexClass];
    }
    
    @Auraenabled(cacheable=true)
    public static List<AuraDefinitionBundle> getLightningComponent()
    {
        return [Select Id,DeveloperName  from AuraDefinitionBundle];
    }
    
    public static List<FieldInfo.Record> getCustomObject()
    {
        string sql='SELECT Id,DeveloperName from CustomObject';
        String result = toolingAPISOQL(sql);
        if(string.isNotBlank(result))
        {
          	FieldInfo data=FieldInfo.parse(result);
          	return data.records;
        }
        return null;
    }
    
    @Auraenabled(cacheable=true)
    public static List<FieldInfo.Record> getObjectFields()
    {
        string sql='SELECT Id,DeveloperName,TableEnumOrId from CustomField';
        String result = toolingAPISOQL(sql);
        if(string.isNotBlank(result))
        {
          	FieldInfo data=FieldInfo.parse(result);
            system.debug('Field Info data parsed'+data.records);
          	return data.records;
        }
        return null;
    }
    
    static String toolingAPISOQL(string query) {
        //String baseURL='callout:ToolingRest?';
        String baseURL=Url.getOrgDomainUrl().toExternalForm()+'/services/data/v58.0/tooling/query?';
        return HttpCallout.restGet( baseURL +'q='+ (query.replace(' ', '+')),'GET');
    } 
    @AuraEnabled(cacheable=true)
    public static List<DependentInfo.Record> getDepdency(string id, list<string> listOfMetadataTypes) {
        //set<string> metadataIds = new set<string>();
      //  String inClause = '(' + String.join(listOfMetadataTypes, '\',\'') + ')';
        listOfMetadataTypes[0] = listOfMetadataTypes[0].remove(', \'SelectAll\'');
        System.debug('---------------SelectAll'+listOfMetadataTypes);
        string sql='Select MetadataComponentId, MetadataComponentName, RefMetadataComponentName, RefMetadataComponentId,MetadataComponentType from MetadataComponentDependency where RefMetadataComponentId=\'id\' AND MetadataComponentType IN '+listOfMetadataTypes;
        system.debug('formed sql is--------'+sql.replace('id',id));
        //'Select MetadataComponentId, MetadataComponentName, RefMetadataComponentName, RefMetadataComponentId,MetadataComponentType from MetadataComponentDependency where RefMetadataComponentId=\'id\'';
        
        String result = toolingAPISOQL(sql.replace('id', id));
        if(string.isNotBlank(result))
        {
          	DependentInfo data=DependentInfo.parse(result);
            
          	return data.records;
        }
        return null;
    }
    
    public class ObjectDetail {
		@AuraEnabled
		public List<FieldInfo.Record> Objects {get;set;} 
        @AuraEnabled
       	public List<FieldInfo.Record> Fields {get;set;} 
        
    } 
    
}