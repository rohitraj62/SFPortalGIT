import { LightningElement, wire } from 'lwc';
import getKnowledgeArticles from '@salesforce/apex/KnowledgeController.getKnowledgeArticles';
import searchKnowledgeArticles from '@salesforce/apex/KnowledgeController.searchKnowledgeArticles';
import getArticleDetails from '@salesforce/apex/KnowledgeController.getArticleDetails';

export default class SelfHelp extends LightningElement {
    articles = [];
    error;
    searchTerm = '';
    selectedArticle = null;
    searchTimeout;

    @wire(getKnowledgeArticles)
    wiredArticles({ error, data }) {
        if (data) {
            this.articles = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.articles = [];
        }
    }

    handleSearchChange(event) {
        this.searchTerm = event.target.value;
        
        if (this.searchTimeout) {
            clearTimeout(this.searchTimeout);
        }
        
        this.searchTimeout = setTimeout(() => {
            if (this.searchTerm && this.searchTerm.length > 2) {
                this.performSearch();
            } else if (!this.searchTerm) {
                this.loadDefaultArticles();
            }
        }, 500);
    }

    handleArticleClick(event) {
        const articleId = event.currentTarget.dataset.id;
        if (articleId) {
            this.loadArticleDetails(articleId);
        }
    }

    handleBackClick() {
        this.selectedArticle = null;
    }

    loadArticleDetails(articleId) {
        getArticleDetails({ articleId: articleId })
            .then(data => {
                this.selectedArticle = data;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
            });
    }

    performSearch() {
        searchKnowledgeArticles({ searchTerm: this.searchTerm })
            .then(data => {
                this.articles = data;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.articles = [];
            });
    }

    loadDefaultArticles() {
        getKnowledgeArticles()
            .then(data => {
                this.articles = data;
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
                this.articles = [];
            });
    }
}