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

        else if(metadataType == 'LightningComponentBundle'){
            return getLightningComponentBundle();
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
                cfRecord.TableEnumOrId=coMap.get(cfRecord.TableEnumOrId)!=null?coMap.get(cfRecord.TableEnumOrId)+'__c': cfRecord.TableEnumOrId;
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

    public static List<SuggestionsWrapper> getLightningComponentBundle(){
        List<SuggestionsWrapper> lightningComponentBundles = new List<SuggestionsWrapper>();
        string lightningComponentBundleSql = 'select id, DeveloperName from LightningComponentBundle';
        List<FieldInfo.Record> lightningComponentBundleResult = invokeToolingAPI(lightningComponentBundleSql);
        for(FieldInfo.Record lightningComponentBundle:lightningComponentBundleResult){
            lightningComponentBundles.add(new SuggestionsWrapper(lightningComponentBundle.Id, lightningComponentBundle.DeveloperName));
        }
        return lightningComponentBundles;

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

    @AuraEnabled
    public static List < resultsWrapper > getDepdency(string id, list<string> objWithField) {
        
        if(id.endsWith('__c')){
              id = getCustomObjectId(id); 

        }
        
        string sql = 'Select MetadataComponentId, MetadataComponentName, RefMetadataComponentName, RefMetadataComponentId,MetadataComponentType from MetadataComponentDependency where RefMetadataComponentId=\'{id}\'';
        system.debug(sql);
        String result = toolingAPISOQL(sql.replace('{id}', id));
        
        if (string.isNotBlank(result)) {
            DependentInfo data = DependentInfo.parse(result);
            List<DependentInfo.Record> records= data.records;
            List<resultsWrapper> results=new List<resultsWrapper>();
            for(DependentInfo.Record record:records){
                if(record.MetadataComponentType == 'Flow'){
                    return checkFlowStatus(data.records);
                    //system.debug('this is in record.MetadataComponentType'+record.MetadataComponentType);
                }
                else 
                    results.add(new resultsWrapper(record.MetadataComponentId, record.MetadataComponentName,record.MetadataComponentType));
            }
           // if(objWithField.size()>0)
            // results.addAll(getListViews(objWithField[0],objWithField[1]);

            return results;
        }
        else 
        return null;
    }

    public static List<resultsWrapper> checkFlowStatus(List<DependentInfo.Record> inputList){
        List<resultsWrapper> results = new List<resultsWrapper>();
        List<String> listofFlow = new List<String>();
        List<DependentInfo.Record> outputList = inputList;
        for(DependentInfo.Record input: outputList){
            // if(input.MetadataComponentType == 'Flow'){
            listofFlow.add('\''+input.MetadataComponentId+'\'');
            // }
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
        for(DependentInfo.Record output: outputList){
            //system.debug('print output'+output);
            results.add(new resultsWrapper(output.MetadataComponentId, output.MetadataComponentName,output.MetadataComponentType));

        }
        return results;
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

    public static void  getListViews(string objectApiName,string fieldApiName){
        string apiPath='/services/data/v58.0/sobjects/'+objectApiName+'/listviews';
        string fullUrl=Url.getOrgDomainUrl().toExternalForm()+apiPath;
        string jsonResponse=HttpCallout.restGet(fullUrl,'GET');
        system.debug('jsonResponse='+jsonResponse);
        system.debug('url='+fullUrl);

    }


    public static String toolingAPISOQL(string query) {
        //String baseURL='callout:ToolingRest?';
        String baseURL = Url.getOrgDomainUrl().toExternalForm() + '/services/data/v58.0/tooling/query?';
        return HttpCallout.restGet(baseURL + 'q=' + (query.replace(' ', '+')), 'GET');
    }


    public class resultsWrapper{
        @AuraEnabled
		public String MetadataComponentId;
        @AuraEnabled
        public string MetadataComponentUrl;
        @AuraEnabled
		public String MetadataComponentName; 
        @AuraEnabled
        public String MetadataComponentType;

        public resultsWrapper(string MetadataComponentId,string MetadataComponentName,string MetadataComponentType){
            this.MetadataComponentId=MetadataComponentId;
            this.MetadataComponentUrl='/'+MetadataComponentId;
            this.MetadataComponentName=MetadataComponentName;
            this.MetadataComponentType=MetadataComponentType;
        }
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


    



}