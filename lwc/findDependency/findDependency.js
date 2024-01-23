import {
    LightningElement,
    track,
    wire,
    api
} from 'lwc';

import getAllObjects from '@salesforce/apex/DependencyController1.getAllObjects';
import getObjectFields from '@salesforce/apex/DependencyController1.getObjectFields';
import getApex from '@salesforce/apex/DependencyController.getApex';
import getLightningComponent from '@salesforce/apex/DependencyController.getLightningComponent';
import getDepdency from '@salesforce/apex/DependencyController1.getDepdency';
//import getCustomObject from '@salesforce/apex/DependencyController1.getCustomObject';



const columnList = [{
        label: 'Metadata Component Name',
        fieldName: 'MetadataComponentName'
    },
    {
        label: 'Metadata Component Type',
        fieldName: 'MetadataComponentType'
    }
];

export default class Dependencynfo extends LightningElement {
    @track objectList = [];
    @track fieldList = [];
    @track fields = [];
    @track objectFields = [];
    @track rows = [];
    @track columns = columnList;
    @track apexList = [];
    @track compList = [];
    error;
    @track type = '';

    @track showDownLoad = false;

    //Adding my code here

    @track selectedMetadataTypes = [];
    @track metadataTypeOptions = [{
            label: 'Flow',
            value: 'Flow'
        },
        {
            label: 'Custom Object',
            value: 'CustomObject'
        },
        {
            label: 'Layout',
            value: 'Layout'
        },
        {
            label: 'Custom Field',
            value: 'CustomField'
        },
        {
            label: 'Apex Class',
            value: 'ApexClass'
        },
        {
            label: 'Apex Page',
            value: 'ApexPage'
        },
        {
            label: 'Apex Trigger',
            value: 'ApexTrigger'
        },
        {
            label: 'Report',
            value: 'Report'
        },
        {
            label: 'Validation Rule',
            value: 'ValidationRule'
        },
        {
            label: 'Lookup Filter',
            value: 'LookupFilter'
        },
        {
            label: 'Experience Bundle',
            value: 'ExperienceBundle'
        },
        {
            label: 'Lightning Component Bundle',
            value: 'LightningComponentBundle'
        }

    ];


    @track selectAllValue = false;
    @track selectAllOption = [{
        label: 'Select All',
        value: 'SelectAll'
    }];

    isApexSelected = false;
    isLightningSelected = false;
    isFieldSelected = false;
    isObjectSelected = false;
    selectedApex = '';
    selectedComp = '';
    object = '';
    selectedField = '';
    selectedObject = '';

    @api
    get types() {
        return [{
                label: 'Please Select',
                value: ''
            },
            {
                label: 'Apex Class',
                value: 'apex'
            },
            {
                label: 'Lightning Component',
                value: 'lightning'
            },
            {
                label: 'Field',
                value: 'field'
            },
            {
                label: 'Object',
                value: 'object'
            },
        ];
    }




    @wire(getAllObjects)
    wiredObject({
        error,
        data
    }) {
        if (data) {

            this.objectList = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
        }
    }

    handleType(event) {
        this.type = event.detail.value;
        this.isFieldSelected = (this.type === 'field');
        this.isLightningSelected = (this.type === 'lightning');
        this.isApexSelected = (this.type === 'apex');
        this.isObjectSelected = (this.type === 'object')
        if (this.isApexSelected) {
            this.getApexList();
        }
        if (this.isLightningSelected) {
            this.getComponentList();
        }

    }

    getApexList() {
        if (this.apexList.length == 0) {
            getApex()
                .then(data => {
                    console.log(JSON.stringify(data));
                    if (data) {
                        this.showDownLoad = true;
                        for (var i = 0; i < data.length; i++) {
                            this.apexList = [...this.apexList, {
                                value: data[i].Id,
                                label: data[i].Name
                            }];
                        }
                    } else if (error) {
                        this.error = error;
                    }
                })
                .catch(error => {
                    this.error = error;
                    console.log(error);
                });
        }
    }
    getComponentList() {
        if (this.compList.length == 0) {
            getLightningComponent()
                .then(data => {
                    if (data) {
                        for (var i = 0; i < data.length; i++) {
                            this.compList = [...this.compList, {
                                value: data[i].Id,
                                label: data[i].DeveloperName
                            }];
                        }
                    } else if (error) {
                        this.error = error;
                    }
                    console.log(JSON.stringify(this.compList));
                })
                .catch(error => {
                    this.error = error;
                    console.log(error);
                });
        }
    }

    handleObjectList(event) {
        this.fieldList = [];
        const selectedOption = event.detail.value;
        this.object = selectedOption;
        getObjectFields({
            objectApiName: this.object
        }).then(data => {
            this.fieldList = data;
        })


    }


    handleObjects(event){
        const selectedObjectOption = event.detail.value;
        this.object = selectedObjectOption;
        
        
    }

    handleFieldList(event) {

        this.selectedField = event.detail.value;
        this.handleDependency(event.detail.value);

    }



    handleFileDownload(event) {
        if (this.fields !== undefined) {
            let csvContent = "data:text/csv;charset=utf-8,";
            
            this.fields.forEach(function(rowArray) {
                let row = rowArray.MetadataComponentName + "," + rowArray.MetadataComponentType + ",";
                csvContent += row + "\r\n";
            });
            var encodedUri = encodeURI(csvContent);
            var link = document.createElement("a");
            link.setAttribute("href", encodedUri);
            link.setAttribute("download", "Dependent.csv");
            document.body.appendChild(link);
            link.click();
            
            
        }
    }

    handleCompChange(event) {
        this.selectedComp = event.detail.value;
        this.handleDependency(event.detail.value);
    }
    handleApexChange(event) {
        this.selectedApex = event.detail.value;
        console.log('selected apexclass Id'+this.selectedApex);
        this.handleDependency(event.detail.value);
    }



    //Adding my code here
    handleFieldSelect(event) {
        this.selectedField = event.detail.value;
    }
    handleMetadataChangeType(event) {
        this.selectedMetadataTypes = event.detail.value;

    }

    //handle submit for selected field
    handleSumit(event) {
        var joinedString = '\'' + this.selectedMetadataTypes.join('\', \'') + '\'';
        console.log('joined string'+joinedString);
        if(this.isApexSelected){
            this.handleDependency(this.selectedApex, joinedString);
        }
        else if(this.isObjectSelected){
            
            this.handleDependency(this.object, joinedString, this.isObjectSelected);

        }
        else
            this.handleDependency(this.selectedField, joinedString);
        
    }

    //this method stores selected metadata types and field Id
    handleDependency(objectId, listOfMetadataTypes, isObjectSelected) {
        getDepdency({
                id: objectId,
                listOfMetadataTypes: listOfMetadataTypes,
                isObjectSelected:isObjectSelected
                
            })
            .then(data => {
                this.showDownLoad = true;
                console.log('data' +listOfMetadataTypes);
                if (data) {
                    this.fields = data;
                    if(this.fields.length == 0){
                        windows.alert('No dependency has been found for the selected field');
                    }
                    this.error = undefined;
                } else if (error) {
                    this.error = error;
                    
                }
                
            })
            .catch(error => {
                
                this.error = error;
                
            });
    }
    //Adding my code here
    handleSelectAll(event) {

        if (this.selectAllValue == false) {
            this.selectAllValue = true;
        } else this.selectAllValue = false;


        if (this.selectAllValue) {
            // If "Select All" is checked, set all metadata types
            this.selectedMetadataTypes = this.metadataTypeOptions.map(option => option.value);
        } else {
            // If "Select All" is unchecked, clear selected metadata types
            this.selectedMetadataTypes = [];
        }
    }

}