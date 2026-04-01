import { LightningElement, wire } from 'lwc';
import getRecentCases from '@salesforce/apex/CaseController.getRecentCases';

export default class MyCases extends LightningElement {
    data = [];
    error;
    sortedBy = 'CreatedDate';
    sortedDirection = 'desc';

    columns = [
        { label: 'Case Number', fieldName: 'CaseNumber', type: 'text', sortable: true },
        { label: 'Subject', fieldName: 'Subject', type: 'text', sortable: true },
        { label: 'Status', fieldName: 'Status', type: 'text', sortable: true },
        { label: 'Priority', fieldName: 'Priority', type: 'text', sortable: true },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date', sortable: true },
        { label: 'Origin', fieldName: 'Origin', type: 'text', sortable: true }
    ];

    @wire(getRecentCases)
    wiredCases({ error, data }) {
        console.log('MyCases - Wire called:', { error, data });
        if (data) {
            console.log('MyCases - Data received:', data);
            this.data = data;
            this.error = undefined;
        } else if (error) {
            console.log('MyCases - Error received:', error);
            this.error = error;
            this.data = [];
        }
    }

    handleSort(event) {
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        this.data = this.sortData([...this.data]);
    }

    sortData(data) {
        const reverse = this.sortedDirection === 'asc' ? 1 : -1;
        return data.sort((a, b) => {
            let aVal = a[this.sortedBy] || '';
            let bVal = b[this.sortedBy] || '';
            
            if (this.sortedBy === 'CreatedDate') {
                aVal = new Date(aVal);
                bVal = new Date(bVal);
            }
            
            return aVal > bVal ? reverse : aVal < bVal ? -reverse : 0;
        });
    }
}