// searchSuggestionsLWC.js
import { LightningElement, track } from 'lwc';
import getSearchSuggestions from '@salesforce/apex/ImpactAnalysisController.getSearchSuggestions';
import getDepdency from '@salesforce/apex/ImpactAnalysisController.getDepdency';
export default class SearchSuggestionsLWC extends LightningElement {
    @track selectedOption;
    @track searchTerm = '';
    @track suggestions = [];
    @track showSuggestions = false;
    @track isLoading = false;
    @track isSearchDisabled=true;

    @track fieldsWithLinks = [];
    @track selectedValue = '';
    @track fields = [];
    @track dropdownOptions = [
        
        {
            label: 'Custom and Standard Object',
            value: 'CustomAndStandardObject'
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
            label: 'Lightning Component Bundle',
            value: 'LightningComponentBundle'
        },
        {
            label: 'Custom Label',
            value: 'CustomLabel'
        },
        
        {
            label: 'Report',
            value: 'Report'
        },
        {
            label: 'Experience Bundle',
            value: 'ExperienceBundle'
        },
        {
            label: 'Email Template',
            value: 'EmailTemplate'
        }

    ];

    handleDropdownChange(event) {
        this.selectedOption = event.detail.value;
        this.isLoading=true;
        console.log('loading' + this.isLoading);
        //console.log(JSON.stringify(this.selectedOption));
        
        this.fetchSuggestions();
    }

    get searchContainerClass() {
            return `slds-col slds-p-relative ${this.selectedOption ? '' : 'slds-is-relative'}`;
        }

    get isSearchDisabled() {
        return !this.selectedOption;
    }

    get searchContainerStyle() {
        return this.showSuggestions ? 'width: 70%' : '';
    }

    get tableContainerStyle() {
        return this.selectedOption ? 'width: 70%' : '';
    }





    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        this.showSuggestions = this.searchTerm.length >= 3;
        this.filterOptions();
        //this.fetchSuggestions();
    }

    filterOptions() {
        this.filteredOptions = this.suggestions.filter(option => option.label.toLowerCase().includes(this.searchTerm.toLowerCase()));
    }

     async fetchSuggestions() {
        if (this.selectedOption.length > 0) {
            try {
                this.suggestions = await getSearchSuggestions({ metadataType: this.selectedOption});
                
            } catch (error) {
                // Handle error
                console.error('Error fetching suggestions:', error);
            }
        } else {
            this.suggestions = [];

        }
        this.isLoading=false;
        this.isSearchDisabled=false;
        const index=this.dropdownOptions.findIndex(obj=>obj.value==this.selectedOption);
        console.log('index='+index)
        this.dropdownOptions[index].label+= ' ('+ this.suggestions.length +')';
        this.dropdownOptions = [...this.dropdownOptions];
    }
    handleSuggestionClick(event) {
        this.selectedValue = event.currentTarget.dataset.value;

        this.selectedOption = this.suggestions.find(option => option.value === this.selectedValue);

        if (this.selectedOption) {
            this.searchTerm = this.selectedOption.label;
            this.showSuggestions = false;
        }
    }


    handleWhereIsThisUsed(event){
        console.log('selected value---'+this.selectedValue);
        this.isLoading = true;
        const objWithField = this.selectedOption.label.split('.');
        console.log('print object and field'+objWithField);
        getDepdency({id: this.selectedValue, objWithField: objWithField})
        .then(data => {
        this.showDownLoad = true;
        if(data){
            console.log('data'+JSON.stringify(this.fields));
            this.fields = data;
            this.isLoading = false;
            }
        })
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


}