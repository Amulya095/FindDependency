public class ImpactAnalysisController {
    
    @AuraEnabled
    public static List<SuggestionsWrapper> getSearchSuggestions(String metadataType) {
        // Add your logic to fetch suggestions based on the searchTerm
        // For example, you might query a custom object, perform a SOSL search, or call an external service.
        // For simplicity, this example returns hardcoded suggestions.
        if(metadataType == 'CustomField')
            return getCustomFields();

        else if(metadataType == 'ApexClass'){
            return getApexClass();

        }

        else if(metadataType == 'EmailTemplate')
            return getEmailTemplate();

        else if(metadataType == 'CustomLabel')
            return getCustomLabel();

        else if(metadataType == 'CustomAndStandardObject'){
            
            return getAllObjects();

        }
            

        else return null;
            
        
        
    }

    public static List<FieldInfo.Record> invokeToolingAPI(string query) {
        //String baseURL='callout:ToolingRest?';
        List<FieldInfo.Record> allRecords = new List<FieldInfo.Record>();
        String baseURL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query?';
        string getResponseBody = HttpCallout.restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET');
        FieldInfo data=FieldInfo.parse(getResponseBody);
        allRecords.addAll(data.records);
        boolean isDone = data.done;
        while(isDone == false){
        	baseURL = Url.getOrgDomainUrl().toExternalForm() + data.nextRecordsUrl;
            system.debug('base url is ------------'+baseURL);
            getResponseBody = HttpCallout.restGet(baseURL, 'GET');
            data=FieldInfo.parse(getResponseBody);
            allRecords.addAll(data.records);
            isDone=data.done;
            
        }
        return allRecords;
    }

    public static List<SuggestionsWrapper> getCustomFields()
    {
        List<SuggestionsWrapper> fields = new List<SuggestionsWrapper>();
        string sql='SELECT Id,DeveloperName,TableEnumOrId from CustomField';
        List<FieldInfo.Record> result = invokeToolingAPI(sql);
        if(result.size()>0){
            string customObjectsSql = 'Select id, DeveloperName from CustomObject';
            List<FieldInfo.Record> customObjectResult = invokeToolingAPI(customObjectsSql);
            map<string,string> coMap=new map<string,string>();
            for(FieldInfo.Record coRecord:customObjectResult ){
                coMap.put(coRecord.Id,coRecord.DeveloperName);
            }
            List<SuggestionsWrapper> suggestions=new List<SuggestionsWrapper>();
            for(FieldInfo.Record cfRecord:result ){
                cfRecord.TableEnumOrId=coMap.get(cfRecord.TableEnumOrId)!=null?coMap.get(cfRecord.TableEnumOrId): cfRecord.TableEnumOrId;
                suggestions.add(new SuggestionsWrapper(cfRecord.Id, cfRecord.TableEnumOrId+'.'+cfRecord.DeveloperName+'__c'));
            }
             return suggestions;

        }
			else return null;       
        
    }

    public static List<SuggestionsWrapper> getCustomLabel(){
        List<SuggestionsWrapper> customLabels = new List<SuggestionsWrapper>();
        string customLabelSql = 'select id, Name from CustomLabel';
        List<FieldInfo.Record> customLabelResult = invokeToolingAPI(customLabelSql);

        for(FieldInfo.Record customLabel : customLabelResult){
            customLabels.add(new SuggestionsWrapper(customLabel.Id, customLabel.Name));
        }
        
        return customLabels;

    }

    
    public static List < SuggestionsWrapper > getAllObjects() {
        system.debug('method called');
        List < SuggestionsWrapper > objectList = new List < SuggestionsWrapper > ();

        //Map<String,String> objectMap = new Map<String,String>();

        for (Schema.SObjectType objTyp: Schema.getGlobalDescribe().Values()) {
            String name = objTyp.getDescribe().getName();
            String label = name;

            if (!name.containsignorecase('history') && !name.containsignorecase('tag') &&
                !name.containsignorecase('share') && !name.containsignorecase('feed') &&
                !name.containsignorecase('group') && !name.containsignorecase('public') && objTyp.getDescribe().isCreateable() &&
                objTyp.getDescribe().getRecordTypeInfos().size() > 0) {
                //objectMap.put(name,label);
                objectList.add(new SuggestionsWrapper(name, label));


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

    public static List<SuggestionsWrapper> getApexClass(){
        List<SuggestionsWrapper> apexClasses = new List<SuggestionsWrapper>();
        List<ApexClass> listOfApexClass = [Select Id,Name from ApexClass];
        for(ApexClass apexClass : listOfApexClass){
            apexClasses.add(new SuggestionsWrapper(apexClass.Id, apexClass.Name));
        }
        
        return apexClasses;

    }

    public static List<SuggestionsWrapper> getEmailTemplate(){
        List<SuggestionsWrapper> emailTemplates = new List<SuggestionsWrapper>();
        List<EmailTemplate> listOfemailTemplate = [Select Id, Name from EmailTemplate ];
        for(EmailTemplate emailTemplate : listOfemailTemplate){
            emailTemplates.add(new SuggestionsWrapper(emailTemplate.Id, emailTemplate.Name));
        }
        
        return emailTemplates;

    }

    public class SuggestionsWrapper{
        @AuraEnabled
        public string value;
        @AuraEnabled
        public string label;
        public SuggestionsWrapper(string id, string name){
            this.value = id;
            this.label = name;

        }
    }


    @AuraEnabled
    public static List < DependentInfo.Record > getDepdency(string id) {
        
        if(id.endsWith('__c')){
              id = getCustomObjectId(id); 

        }
        
        string sql = 'Select MetadataComponentId, MetadataComponentName, RefMetadataComponentName, RefMetadataComponentId,MetadataComponentType from MetadataComponentDependency where RefMetadataComponentId=\'{id}\'';
        system.debug(sql);
        String result = toolingAPISOQL(sql.replace('{id}', id));
        
        if (string.isNotBlank(result)) {
            DependentInfo data = DependentInfo.parse(result);
            //if(listOfMetadataTypes[0].contains('Flow'))
              //  return checkFlowStatus(data.records);
            system.debug('---------------------'+data.records);
            return data.records;
        }
        else 
        return null;
    }

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

    public static String toolingAPISOQL(string query) {
        //String baseURL='callout:ToolingRest?';
        String baseURL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query?';
        return HttpCallout.restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET');
    }



}