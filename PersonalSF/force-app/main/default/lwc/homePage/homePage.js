import { LightningElement, wire } from 'lwc';
import CC_HomeBanner from '@salesforce/resourceUrl/CC_HomeBanner';
import getRecentCases from '@salesforce/apex/CaseController.getRecentCases';

export default class HomePage extends LightningElement {
    CC_HomeBanner = CC_HomeBanner;
    data = [];
    error;
    
    columns = [
        { label: 'Case Number', fieldName: 'CaseNumber', type: 'text' },
        { label: 'Subject', fieldName: 'Subject', type: 'text' },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Priority', fieldName: 'Priority', type: 'text' },
        { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
        { label: 'Origin', fieldName: 'Origin', type: 'text' }
    ];

    @wire(getRecentCases)
    wiredCases({ error, data }) {
        if (data) {
            this.data = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = [];
        }
    }
}