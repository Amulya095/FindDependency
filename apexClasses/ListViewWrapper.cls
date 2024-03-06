public class ListViewWrapper {
    public string Done{get;set;}
    public List<listviews> listviews{get;set;}
    public List<columns> columns{get;set;}
    public string sobjectType{get;set;}


public class listviews{
    public string describeUrl{get;set;}
    public string developerName{get;set;}
    public string id{get;set;}
    public string label{get;set;}
}


public class columns{
    public string label{get;set;}
    public string fieldNameOrPath{get;set;} 
    
}
public static ListViewWrapper parse(string json){
    return (ListViewWrapper) system.json.deserialize(json, ListViewWrapper.class);
    }
}