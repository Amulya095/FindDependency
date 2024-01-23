public class DependencyController1 {

    //Retrieve All Objects in org


    @Auraenabled(cacheable = true)
    public static List < CustomObjectWrapper > getAllObjects() {
        system.debug('method called');
        List < CustomObjectWrapper > objectList = new List < CustomObjectWrapper > ();

        //Map<String,String> objectMap = new Map<String,String>();

        for (Schema.SObjectType objTyp: Schema.getGlobalDescribe().Values()) {
            String name = objTyp.getDescribe().getName();
            String label = name;

            if (!name.containsignorecase('history') && !name.containsignorecase('tag') &&
                !name.containsignorecase('share') && !name.containsignorecase('feed') &&
                !name.containsignorecase('group') && !name.containsignorecase('public') && objTyp.getDescribe().isCreateable() &&
                objTyp.getDescribe().getRecordTypeInfos().size() > 0) {
                //objectMap.put(name,label);
                objectList.add(new CustomObjectWrapper(name, label));


            }
        }

        if (objectList != null && objectList.size() > 0) {
            system.debug('inside if not null' + objectList);
            return objectList;
        } else {
            system.debug('inside Else null');

            return null;
        }


    }
    @Auraenabled(cacheable = true)
    public static List < CustomObjectWrapper > getObjectFields(string objectApiName) {
        String tableEnumOrId = objectApiName;
        List < CustomObjectWrapper > fields = new List < CustomObjectWrapper > ();
        if (objectApiName.endsWith('__c')) {
            string objectSql = 'SELECT Id,DeveloperName from CustomObject where DeveloperName=\'{DeveloperName}\'';
            String customObjectResult = toolingAPISOQL(objectSql.replace('{DeveloperName}', objectApiName.removeEnd('__c')));
            if (string.isNotBlank(customObjectResult)) {
                FieldInfo data = FieldInfo.parse(customObjectResult);
                tableEnumOrId = data.records[0].Id;

            }
        }
        string fieldSql = 'SELECT Id,DeveloperName from CustomField where TableEnumOrId=\'{tableEnumOrId}\'';
        String customFieldResult = toolingAPISOQL(fieldSql.replace('{tableEnumOrId}', tableEnumOrId));
        if (string.isNotBlank(customFieldResult)) {
            FieldInfo data = FieldInfo.parse(customFieldResult);
            for (FieldInfo.Record field: data.records) {
                fields.add(new CustomObjectWrapper(field.Id, field.DeveloperName + '__c'));
            }
        }


        return fields;
    }


    public static String toolingAPISOQL(string query) {
        //String baseURL='callout:ToolingRest?';
        String baseURL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query?';
        return HttpCallout.restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET');
    }

//this is to get the custom object Id
    public static string getCustomObjectId(string objectApiName){
        String customObjectId = objectApiName;
        string customObjectSql = 'SELECT Id,DeveloperName from CustomObject where DeveloperName=\'{DeveloperName}\'';
        String customObjectResult = toolingAPISOQL(customObjectSql.replace('{DeveloperName}', objectApiName.removeEnd('__c')));
            if (string.isNotBlank(customObjectResult)) {
                FieldInfo data = FieldInfo.parse(customObjectResult);
                customObjectId = data.records[0].Id;
                system.debug('the id fetched is---'+customObjectId);
                return customObjectId;

            }
            else return null;

    }

    @AuraEnabled(cacheable = false)
    public static List < DependentInfo.Record > getDepdency(string id, list<string> listOfMetadataTypes, boolean isObjectSelected) {
        
        if(isObjectSelected == true && id.endsWith('__c')){
            id = getCustomObjectId(id); 

        }
        
        string sql = 'Select MetadataComponentId, MetadataComponentName, RefMetadataComponentName, RefMetadataComponentId,MetadataComponentType from MetadataComponentDependency where RefMetadataComponentId=\'{id}\' AND MetadataComponentType IN ' + listOfMetadataTypes;
        system.debug(sql);
        String result = toolingAPISOQL(sql.replace('{id}', id));
        
        if (string.isNotBlank(result)) {
            DependentInfo data = DependentInfo.parse(result);
            if(listOfMetadataTypes[0].contains('Flow'))
                return checkFlowStatus(data.records);
            else return data.records;
        }
        return null;
    }


    
    
    
    //check for flow status
    public static List<DependentInfo.Record> checkFlowStatus(List<DependentInfo.Record> inputList){
        List<String> listofFlow = new List<String>();
        List<DependentInfo.Record> outputList = inputList;
        for(DependentInfo.Record input: outputList){
            if(input.MetadataComponentType == 'Flow'){
                listofFlow.add('\''+input.MetadataComponentId+'\'');
            }
        }
        if(listofFlow.size()>0){

      
        string lf='('+string.join(listofFlow,',')+')';
        string flowSql = 'SELECT Id, status from Flow where Id IN '+lf ;
        
        String flowResult = toolingAPISOQL(flowSql);
        system.debug('flowResult the query' +flowResult);
        if (string.isNotBlank(flowResult)) {
            FieldInfo data = FieldInfo.parse(flowResult);
            for (FieldInfo.Record field: data.records) {
                for(DependentInfo.Record input: outputList){
                    if(field.Id == input.MetadataComponentId){
                        if(field.Status=='Obsolete')
                            input.MetadataComponentName+= ' (InActive)';
                        else
                        input.MetadataComponentName+= ' ('+field.Status+')';
                    }
                }
            }
        }
        }
        return outputList;
    }

    //Creating a wrapper class to handle the name label formatting
    public class CustomObjectWrapper {
        @auraEnabled
        public String value;
        @auraEnabled
        public String label;

        public CustomObjectWrapper(String name, String label) {
            this.value = name;
            this.label = label;
        }
    }

}