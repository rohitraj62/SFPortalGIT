import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import CC_Logo from '@salesforce/resourceUrl/CC_Logo';

export default class Header extends NavigationMixin(LightningElement) {
    CC_Logo = CC_Logo;
    showCasesDropdown = false;
    userId = Id;
    userName = 'User';

    @wire(getRecord, { recordId: '$userId', fields: [NAME_FIELD] })
    user({ error, data }) {
        if (data) {
            this.userName = data.fields.Name.value;
        }
    }

    get isLoggedIn() {
        return this.userId != null;
    }

    get casesDropdownClass() {
        return this.showCasesDropdown ? 'dropdown-content show' : 'dropdown-content';
    }

    toggleCasesDropdown() {
        this.showCasesDropdown = !this.showCasesDropdown;
    }

    goHome() {
        this.showCasesDropdown = false;
        window.location.href = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s/';
    }

    goMyCases() {
        this.showCasesDropdown = false;
        this.dispatchEvent(new CustomEvent('navigate', { detail: { page: 'mycases' } }));
    }

    goCreateCase() {
        this.showCasesDropdown = false;
        window.location.href = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s/Create/case';
    }

    goSelfHelp() {
        this.showCasesDropdown = false;
        window.location.href = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s/selfhelp';
        this.dispatchEvent(new CustomEvent('navigate', { detail: { page: 'selfhelp' } }));
    }

    handleLogout() {
        window.location.href = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/secur/logout.jsp';
    }
}