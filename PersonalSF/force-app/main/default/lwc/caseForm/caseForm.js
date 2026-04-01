import { LightningElement, wire } from 'lwc';
import createCase from '@salesforce/apex/CaseController.createCase';
import getAccountAssets from '@salesforce/apex/CaseController.getAccountAssets';
import checkWarranty from '@salesforce/apex/CaseController.checkWarranty';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class CaseForm extends NavigationMixin(LightningElement) {
    subject = '';
    description = '';
    priority = 'Medium';
    origin = 'Web';
    selectedAsset = '';
    caseType = 'Product Support';
    isLoading = false;
    showSuccess = false;
    createdCaseNumber = '';
    warrantyMessage = '';
    isWarrantyValid = false;
    assets = [];
    showWarrantyError = false;
    entitlementDetails = {};
    supportType = '';
    caseLimit = 0;

    priorityOptions = [
        { label: 'High', value: 'High' },
        { label: 'Medium', value: 'Medium' },
        { label: 'Low', value: 'Low' }
    ];

    @wire(getAccountAssets)
    wiredAssets({ error, data }) {
        if (data) {
            this.assets = data.map(asset => ({
                label: `${asset.Name} (Serial: ${asset.SerialNumber})`,
                value: asset.Id
            }));
        }
    }

    get showPrioritySelection() {
        return this.isWarrantyValid;
    }

    get warrantyMessageClass() {
        return this.showWarrantyError ? 'warranty-message error' : 'warranty-message success';
    }

    get isCreateDisabled() {
        return this.isLoading || !this.selectedAsset || this.showWarrantyError;
    }

    handleSubjectChange(event) {
        this.subject = event.target.value;
        this.hideSuccessMessage();
    }

    handleDescriptionChange(event) {
        this.description = event.target.value;
        this.hideSuccessMessage();
    }

    handlePriorityChange(event) {
        this.priority = event.target.value;
        this.hideSuccessMessage();
    }

    async handleAssetChange(event) {
        this.selectedAsset = event.target.value;
        this.hideSuccessMessage();
        if (this.selectedAsset) {
            try {
                const result = await checkWarranty({ assetId: this.selectedAsset });
                this.warrantyMessage = result.message;
                this.isWarrantyValid = result.isValid;
                this.showWarrantyError = !result.isValid;
                this.entitlementDetails = result.entitlementDetails || {};
                
                // Display entitlement details if available
                if (result.isValid && this.entitlementDetails.supportType) {
                    this.supportType = this.entitlementDetails.supportType;
                    this.warrantyMessage += ` | Support: ${this.supportType}`;
                }
                
                if (!result.isValid) {
                    this.priority = 'Low';
                }
            } catch (error) {
                this.showToast('Error', 'Error checking warranty', 'error');
            }
        }
    }

    async handleCreateCase() {
        if (!this.subject) {
            this.showToast('Error', 'Subject is required', 'error');
            return;
        }

        if (this.showWarrantyError) {
            this.showToast('Error', 'Cannot create case - warranty/entitlement has expired', 'error');
            return;
        }

        if (!this.selectedAsset) {
            this.showToast('Error', 'Please select an asset for product support', 'error');
            return;
        }

        this.isLoading = true;
        try {
            const caseNumber = await createCase({
                subject: this.subject,
                description: this.description,
                priority: this.priority,
                origin: this.origin,
                assetId: this.selectedAsset,
                caseType: this.caseType
            });
            
            this.createdCaseNumber = caseNumber;
            this.showSuccess = true;
            this.resetForm();
            this.showToast('Success', `Case ${caseNumber} created successfully!`, 'success');
            
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleCancel() {
        this.resetForm();
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    resetForm() {
        this.subject = '';
        this.description = '';
        this.priority = 'Medium';
        this.origin = 'Web';
        this.selectedAsset = '';
        this.caseType = 'Product Support';
        this.warrantyMessage = '';
        this.showWarrantyError = false;
        this.isWarrantyValid = false;
        this.entitlementDetails = {};
        this.supportType = '';
        this.caseLimit = 0;
    }

    hideSuccessMessage() {
        if (this.showSuccess) {
            this.showSuccess = false;
        }
    }

    navigateToMyCases() {
        this.dispatchEvent(new CustomEvent('navigatetomycases'));
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            title,
            message,
            variant
        }));
    }
}