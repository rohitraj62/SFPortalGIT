public with sharing class CaseController {
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getRecentCases() {
        try {
            Id currentUserId = UserInfo.getUserId();
            
            // Get the Contact associated with the current user (for Experience Cloud users)
            List<User> currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            if (currentUser.isEmpty() || currentUser[0].ContactId == null) {
                return new List<Case>();
            }
            
            Id contactId = currentUser[0].ContactId;
            
            // Get the Account associated with the Contact
            List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            
            if (contacts.isEmpty()) {
                return new List<Case>();
            }
            
            Id accountId = contacts[0].AccountId;
            
            // Fetch recent cases for the account
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, IsEscalated, 
                       Description, CreatedDate, Origin, LastModifiedDate
                FROM Case 
                WHERE AccountId = :accountId 
                ORDER BY CreatedDate DESC 
                LIMIT 5
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching cases: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Case> getAllCases(Integer pageSize, Integer pageNumber) {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<User> currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            if (currentUser.isEmpty() || currentUser[0].ContactId == null) {
                return new List<Case>();
            }
            
            Id contactId = currentUser[0].ContactId;
            List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            
            if (contacts.isEmpty()) {
                return new List<Case>();
            }
            
            Id accountId = contacts[0].AccountId;
            Integer offset = (pageNumber - 1) * pageSize;
            
            return [
                SELECT Id, CaseNumber, Subject, Status, Priority, IsEscalated, 
                       Description, CreatedDate, Origin, LastModifiedDate
                FROM Case 
                WHERE AccountId = :accountId 
                ORDER BY CreatedDate DESC 
                LIMIT :pageSize OFFSET :offset
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching cases: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Asset> getAccountAssets() {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<User> currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            if (currentUser.isEmpty() || currentUser[0].ContactId == null) {
                return new List<Asset>();
            }
            
            Id contactId = currentUser[0].ContactId;
            List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            
            if (contacts.isEmpty()) {
                return new List<Asset>();
            }
            
            Id accountId = contacts[0].AccountId;
            
            return [
                SELECT Id, Name, Product2.Name, SerialNumber, InstallDate, 
                       UsageEndDate, Status
                FROM Asset 
                WHERE AccountId = :accountId AND Status = 'Installed'
                ORDER BY Name
            ];
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching assets: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Map<String, Object> checkWarranty(Id assetId) {
        try {
            // Check entitlements for the asset (PRIMARY VALIDATION)
            List<Entitlement> entitlements = [
                SELECT Id, Name, StartDate, EndDate, Status, Asset.Name, Asset.SerialNumber,
                       Type, ServiceContract.Name, ServiceContract.EndDate
                FROM Entitlement 
                WHERE AssetId = :assetId AND Status = 'Active'
                ORDER BY EndDate DESC
                LIMIT 1
            ];
            
            Boolean isWarrantyValid = false;
            String message = '';
            Map<String, Object> entitlementDetails = new Map<String, Object>();
            
            if (!entitlements.isEmpty()) {
                Entitlement entitlement = entitlements[0];
                if (entitlement.EndDate >= Date.today()) {
                    isWarrantyValid = true;
                    message = 'Support entitlement active until ' + entitlement.EndDate.format();
                    
                    // Return entitlement details for case creation
                    entitlementDetails.put('entitlementId', entitlement.Id);
                    entitlementDetails.put('supportType', entitlement.Type);
                    entitlementDetails.put('contractName', entitlement.ServiceContract.Name);
                } else {
                    message = 'Support entitlement expired on ' + entitlement.EndDate.format();
                }
            } else {
                // Fallback to asset warranty check
                List<Asset> assets = [
                    SELECT Id, Name, UsageEndDate, SerialNumber
                    FROM Asset 
                    WHERE Id = :assetId
                    LIMIT 1
                ];
                
                if (!assets.isEmpty()) {
                    Asset asset = assets[0];
                    if (asset.UsageEndDate != null) {
                        if (asset.UsageEndDate >= Date.today()) {
                            isWarrantyValid = true;
                            message = 'Asset warranty valid until ' + asset.UsageEndDate.format();
                        } else {
                            message = 'Asset warranty expired on ' + asset.UsageEndDate.format();
                        }
                    } else {
                        message = 'No warranty or entitlement information available';
                    }
                } else {
                    throw new AuraHandledException('Asset not found');
                }
            }
            
            return new Map<String, Object>{
                'isValid' => isWarrantyValid,
                'message' => message,
                'entitlementDetails' => entitlementDetails
            };
            
        } catch (Exception e) {
            throw new AuraHandledException('Error checking warranty: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String createCase(String subject, String description, String priority, String origin, Id assetId, String caseType) {
        try {
            Id currentUserId = UserInfo.getUserId();
            List<User> currentUser = [SELECT ContactId FROM User WHERE Id = :currentUserId LIMIT 1];
            
            if (currentUser.isEmpty() || currentUser[0].ContactId == null) {
                throw new AuraHandledException('User not associated with a contact');
            }
            
            Id contactId = currentUser[0].ContactId;
            List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
            
            if (contacts.isEmpty()) {
                throw new AuraHandledException('Contact not associated with an account');
            }
            
            // Get entitlement for the asset (REQUIRED for Service Cloud)
            Id entitlementId = null;
            if (assetId != null) {
                List<Entitlement> entitlements = [
                    SELECT Id, Name, Type
                    FROM Entitlement 
                    WHERE AssetId = :assetId AND Status = 'Active' 
                    AND StartDate <= TODAY AND EndDate >= TODAY
                    ORDER BY EndDate DESC
                    LIMIT 1
                ];
                
                if (!entitlements.isEmpty()) {
                    entitlementId = entitlements[0].Id;
                } else {
                    throw new AuraHandledException('No valid entitlement found for this asset');
                }
            }
            
            Case newCase = new Case(
                Subject = subject,
                Description = description,
                Priority = priority,
                Origin = origin,
                ContactId = contactId,
                AccountId = contacts[0].AccountId,
                AssetId = assetId,
                EntitlementId = entitlementId,
                Type = caseType,
                Status = 'New'
            );
            
            insert newCase;
            
            // Query the case to get the CaseNumber
            Case createdCase = [SELECT CaseNumber FROM Case WHERE Id = :newCase.Id LIMIT 1];
            return createdCase.CaseNumber;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error creating case: ' + e.getMessage());
        }
    }
}