import { LightningElement } from 'lwc';

export default class LoginRegister extends LightningElement {
    showLogin = true;
    username = '';
    password = '';
    firstName = '';
    lastName = '';
    email = '';

    get showRegister() {
        return !this.showLogin;
    }

    get authTitle() {
        return this.showLogin ? 'Login' : 'Register';
    }

    handleUsernameChange(event) {
        this.username = event.target.value;
    }

    handlePasswordChange(event) {
        this.password = event.target.value;
    }

    handleFirstNameChange(event) {
        this.firstName = event.target.value;
    }

    handleLastNameChange(event) {
        this.lastName = event.target.value;
    }

    handleEmailChange(event) {
        this.email = event.target.value;
    }

    switchToRegister(event) {
        event.preventDefault();
        this.showLogin = false;
        this.clearForm();
    }

    switchToLogin(event) {
        event.preventDefault();
        this.showLogin = true;
        this.clearForm();
    }

    handleLogin() {
        // Redirect to Salesforce login
        const baseUrl = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s';
        window.location.href = `${baseUrl}/login`;
    }

    handleRegister() {
        // Redirect to Salesforce registration
        const baseUrl = 'https://cloudanalogy-1ac-dev-ed.develop.my.site.com/main/s';
        window.location.href = `${baseUrl}/SelfRegister`;
    }

    clearForm() {
        this.username = '';
        this.password = '';
        this.firstName = '';
        this.lastName = '';
        this.email = '';
    }
}