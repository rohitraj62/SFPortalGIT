public with sharing class KnowledgeController {
    
    @AuraEnabled(cacheable=true)
    public static List<KnowledgeArticleVersion> getKnowledgeArticles() {
        try {
            return [
                SELECT Id, Title, Summary, UrlName, ArticleNumber, 
                       LastPublishedDate
                FROM KnowledgeArticleVersion 
                WHERE PublishStatus = 'Online' 
                AND Language = 'en_US'
                ORDER BY LastPublishedDate DESC 
                LIMIT 10
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching knowledge articles: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<KnowledgeArticleVersion> searchKnowledgeArticles(String searchTerm) {
        try {
            String searchQuery = '%' + searchTerm + '%';
            return [
                SELECT Id, Title, Summary, UrlName, ArticleNumber, 
                       LastPublishedDate
                FROM KnowledgeArticleVersion 
                WHERE PublishStatus = 'Online' 
                AND Language = 'en_US'
                AND (Title LIKE :searchQuery OR Summary LIKE :searchQuery)
                ORDER BY LastPublishedDate DESC 
                LIMIT 20
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error searching knowledge articles: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static KnowledgeArticleVersion getArticleDetails(String articleId) {
        try {
            return [
                SELECT Id, Title, Summary, UrlName, ArticleNumber, 
                       LastPublishedDate
                FROM KnowledgeArticleVersion 
                WHERE Id = :articleId 
                AND PublishStatus = 'Online'
                LIMIT 1
            ][0];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching article details: ' + e.getMessage());
        }
    }
}