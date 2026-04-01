import { LightningElement } from 'lwc';
import Id from '@salesforce/user/Id';

export default class CustomerConnectMain extends LightningElement {
    currentPage = 'home';
    userId = Id;

    connectedCallback() {
        this.determineCurrentPage();
    }

    determineCurrentPage() {
        const path = window.location.pathname;
        
        if (path.includes('/raisecase/')) {
            this.currentPage = 'createcase';
        } else if (path.includes('/cases/')) {
            this.currentPage = 'mycases';
        } else {
            this.currentPage = 'home';
        }
    }

    get isLoggedIn() {
        return this.userId != null;
    }

    get showHome() {
        return this.currentPage === 'home' && this.isLoggedIn;
    }

    get showMyCases() {
        return this.currentPage === 'mycases' && this.isLoggedIn;
    }

    get showCreateCase() {
        return this.currentPage === 'createcase' && this.isLoggedIn;
    }

    get showSelfHelp() {
        return this.currentPage === 'selfhelp' && this.isLoggedIn;
    }

    get showLogin() {
        return !this.isLoggedIn;
    }

    handleNavigation(event) {
        this.currentPage = event.detail.page;
    }

    handleCancelForm() {
        window.location.href = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s/';
    }
}