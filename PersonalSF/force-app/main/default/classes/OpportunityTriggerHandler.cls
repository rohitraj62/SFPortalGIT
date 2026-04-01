/**
 * SERVICE CLOUD OBJECTS EXPLANATION
 * 
 * This trigger creates a complete Service Cloud ecosystem when opportunities are closed won.
 * 
 * REAL-WORLD SCENARIO: Customer buys Samsung S24 phone
 * 
 * 1. ASSET - The actual product customer owns
 *    Example: Samsung S24 with serial HW-001-12345
 *    
 *    REQUIRED FIELDS:
 *    - Name: Product name + type + sequence ("Samsung S24 - Unit 1")
 *    - AccountId: Which customer owns this asset
 *    - Product2Id: Links to the product catalog
 *    
 *    IMPORTANT FIELDS:
 *    - SerialNumber: Unique identifier (HW-001-12345)
 *    - Status: Asset lifecycle (Installed, Shipped, Obsolete)
 *    - InstallDate: When customer received/installed
 *    - UsageEndDate: When warranty/support expires
 *    - ContactId: Primary contact for this asset
 *    
 *    WHAT THEY REPRESENT:
 *    - Name: Human-readable asset identifier
 *    - SerialNumber: Unique tracking number for support
 *    - InstallDate: Start of warranty period
 *    - UsageEndDate: End of warranty/support coverage
 *    - Status: Current state of the asset
 *    
 *    Think of it as: Physical product receipt with warranty info
 * 
 * 2. SERVICE CONTRACT - The warranty/support agreement
 *    Example: "Hardware Support Contract - Samsung S24"
 *    
 *    REQUIRED FIELDS:
 *    - Name: Contract identifier
 *    - AccountId: Which customer has this contract
 *    - StartDate: When contract becomes active
 *    - EndDate: When contract expires
 *    
 *    IMPORTANT FIELDS:
 *    - Term: Contract duration in months (24 for hardware, 12 for software)
 *    - Status: Contract state (Draft, Active, Expired)
 *    - ContractNumber: Auto-generated unique identifier
 *    - Description: Contract terms and conditions
 *    
 *    WHAT THEY REPRESENT:
 *    - Name: Type of support provided
 *    - StartDate/EndDate: Coverage period
 *    - Term: How long support lasts
 *    - Status: Whether contract is currently valid
 *    
 *    Think of it as: Warranty booklet that comes with phone
 * 
 * 3. CONTRACT LINE ITEM - Links specific product to warranty
 *    Example: "This Samsung S24 (HW-001-12345) is covered under warranty #12345"
 *    
 *    REQUIRED FIELDS:
 *    - ServiceContractId: Which contract covers this
 *    - AssetId: Which asset is covered
 *    - PricebookEntryId: Product pricing reference
 *    - Quantity: How many units covered (usually 1)
 *    - UnitPrice: Cost of coverage (often 0 for included warranty)
 *    
 *    IMPORTANT FIELDS:
 *    - StartDate: When coverage begins for this asset
 *    - EndDate: When coverage ends for this asset
 *    - Discount: Any discount applied to coverage
 *    - LineNumber: Order of items in contract
 *    
 *    WHAT THEY REPRESENT:
 *    - ServiceContractId + AssetId: "This asset is covered by this contract"
 *    - StartDate/EndDate: Specific coverage period for this asset
 *    - Quantity: Number of units covered
 *    - UnitPrice: Cost per unit of coverage
 *    
 *    Think of it as: Line in warranty contract listing your specific phone
 * 
 * 4. ENTITLEMENT - Customer's support rights and what they can do
 *    Example: "You can call support unlimited times for 2 years"
 *    
 *    REQUIRED FIELDS:
 *    - Name: Entitlement identifier
 *    - AccountId: Which customer has these rights
 *    - StartDate: When support rights begin
 *    - EndDate: When support rights expire
 *    
 *    IMPORTANT FIELDS:
 *    - AssetId: Which asset this entitlement covers
 *    - ServiceContractId: Which contract grants these rights
 *    - Type: Support channel (Phone, Web, Email)
 *    - CasesPerEntitlement: How many cases allowed
 *    - Status: Whether entitlement is active
 *    - BusinessHoursId: When support is available
 *    
 *    WHAT THEY REPRESENT:
 *    - Type: How customer can get support (phone vs web)
 *    - CasesPerEntitlement: Support usage limits
 *    - StartDate/EndDate: When customer can use support
 *    - AssetId: Which product this support covers
 *    
 *    Think of it as: Support membership card with rules
 * 
 * 5. CASE - Actual support request (created later in portal)
 *    Example: "My Samsung S24 screen is cracked, please help"
 *    
 *    REQUIRED FIELDS:
 *    - Subject: Brief description of issue
 *    - AccountId: Which customer needs help
 *    
 *    IMPORTANT FIELDS:
 *    - AssetId: Which product has the issue
 *    - EntitlementId: Which support rights are being used
 *    - ContactId: Who to contact about this case
 *    - Priority: How urgent (High, Medium, Low)
 *    - Status: Case progress (New, In Progress, Closed)
 *    - Origin: How case was created (Web, Phone, Email)
 *    - Description: Detailed problem description
 *    
 *    WHAT THEY REPRESENT:
 *    - Subject: What's wrong in simple terms
 *    - AssetId: Which product needs help
 *    - Priority: How quickly to respond
 *    - Status: Current stage of resolution
 *    
 *    Think of it as: Support ticket/request
 * 
 * FLOW: Buy Product → Asset → Service Contract → Contract Line Item → Entitlement → Case Creation
 * 
 * PORTAL INTEGRATION:
 * - Asset Selection: Shows products customer owns
 * - Warranty Check: Validates entitlements before case creation
 * - Support Level: Determines priority options based on entitlement type
 * - Case Limits: Tracks usage against entitlement limits
 */
public class OpportunityTriggerHandler {
    
    public static void handleAfterUpdate(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunityMap) {
        List<Opportunity> closedWonOpportunities = new List<Opportunity>();
        
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            
            // Check if opportunity just changed to Closed Won
            if (opp.StageName == 'Closed Won' && oldOpp.StageName != 'Closed Won') {
                closedWonOpportunities.add(opp);
            }
        }
        
        if (!closedWonOpportunities.isEmpty()) {
            createServiceCloudRecords(closedWonOpportunities);
        }
    }
    
    public static void createServiceCloudRecords(List<Opportunity> opportunities) {
        List<Asset> assetsToCreate = new List<Asset>();
        List<ServiceContract> contractsToCreate = new List<ServiceContract>();
        
        // Get opportunity line items with products
        Map<Id, List<OpportunityLineItem>> oppLineItemsMap = new Map<Id, List<OpportunityLineItem>>();
        for (OpportunityLineItem oli : [
            SELECT Id, OpportunityId, Product2Id, Product2.Name, Product2.ProductCode, Quantity, 
                   PricebookEntryId, PricebookEntry.Pricebook2Id, Opportunity.AccountId, Opportunity.Account.Name
            FROM OpportunityLineItem 
            WHERE OpportunityId IN :opportunities
        ]) {
            if (!oppLineItemsMap.containsKey(oli.OpportunityId)) {
                oppLineItemsMap.put(oli.OpportunityId, new List<OpportunityLineItem>());
            }
            oppLineItemsMap.get(oli.OpportunityId).add(oli);
        }
        
        // Process each opportunity
        for (Opportunity opp : opportunities) {
            if (oppLineItemsMap.containsKey(opp.Id)) {
                List<OpportunityLineItem> lineItems = oppLineItemsMap.get(opp.Id);
                
                // Create assets based on products sold
                for (OpportunityLineItem oli : lineItems) {
                    // Create ONE asset per OpportunityLineItem (not per quantity)
                    Asset asset = createAssetForProduct(oli, opp.AccountId);
                    if (asset != null) {
                        assetsToCreate.add(asset);
                    }
                    
                    // Create service contract for this product type
                    ServiceContract contract = createServiceContractForProduct(oli, opp.AccountId);
                    if (contract != null) {
                        contractsToCreate.add(contract);
                    }
                }
            }
        }
        
        // Insert service contracts first
        if (!contractsToCreate.isEmpty()) {
            insert contractsToCreate;
        }
        
        // Insert assets
        if (!assetsToCreate.isEmpty()) {
            insert assetsToCreate;
            
            // Create contract line items and entitlements
            createContractLineItemsAndEntitlements(assetsToCreate, contractsToCreate, oppLineItemsMap);
        }
    }
    
    /**
     * ASSET CREATION
     * Creates ONE asset per OpportunityLineItem (not per quantity)
     * Example: Samsung S24 OpportunityLineItem becomes "Samsung S24 - Asset" with serial HW-001-12345
     * 
     * Hardware Products (S24, Laptop): 2-year warranty, HW- serial, "Unit" type
     * Software Products (Others): 1-year support, PRD- serial, "License" type
     */
    private static Asset createAssetForProduct(OpportunityLineItem oli, Id accountId) {
        String productName = oli.Product2.Name;
        String productCode = oli.Product2.ProductCode;
        
        // Determine product type and warranty period
        Integer warrantyYears = 1; // Default 1 year
        String serialPrefix = 'PRD';
        String assetType = 'License';
        
        // Check if it's a hardware product (contains keywords like S24, Laptop, etc.)
        if (productName.containsIgnoreCase('S24') || 
            productName.containsIgnoreCase('Laptop') || 
            productName.containsIgnoreCase('Hardware') ||
            productCode != null && productCode.containsIgnoreCase('SAMG')) {
            warrantyYears = 2;
            serialPrefix = 'HW';
            assetType = 'Unit';
        }
        
        return new Asset(
            Name = productName + ' - ' + assetType,
            Product2Id = oli.Product2Id,
            AccountId = accountId,
            Status = 'Installed',
            InstallDate = Date.today(),
            UsageEndDate = Date.today().addYears(warrantyYears),
            SerialNumber = serialPrefix + '-' + String.valueOf(oli.Id).right(8) + '-' + String.valueOf(System.now().millisecond()),
            Quantity = oli.Quantity  // Store OLI quantity in asset
        );
    }
    
    /**
     * SERVICE CONTRACT CREATION
     * Creates the warranty/support agreement for the product
     * Example: "Hardware Support Contract - Samsung S24" valid for 2 years
     * 
     * This is like the warranty booklet - defines what support customer gets
     */
    private static ServiceContract createServiceContractForProduct(OpportunityLineItem oli, Id accountId) {
        String productName = oli.Product2.Name;
        String productCode = oli.Product2.ProductCode;
        
        // Determine contract type and duration
        Integer contractYears = 1; // Default 1 year
        String contractType = 'Software Support';
        
        // Check if it's a hardware product
        if (productName.containsIgnoreCase('S24') || 
            productName.containsIgnoreCase('Laptop') || 
            productName.containsIgnoreCase('Hardware') ||
            productCode != null && productCode.containsIgnoreCase('SAMG')) {
            contractYears = 2;
            contractType = 'Hardware Support';
        }
        
        return new ServiceContract(
            Name = contractType + ' Contract - ' + productName,
            AccountId = accountId,
            StartDate = Date.today(),
            EndDate = Date.today().addYears(contractYears),
            Term = contractYears * 12,
            Pricebook2Id = oli.PricebookEntry.Pricebook2Id
        );
    }
    
    /**
     * CONTRACT LINE ITEM & ENTITLEMENT CREATION
     * 
     * CONTRACT LINE ITEM: Links specific asset to service contract
     * Example: "Samsung S24 (HW-001-12345) is covered under warranty contract #12345"
     * 
     * ENTITLEMENT: Defines customer's support rights
     * Example: "You can call support unlimited times for Samsung S24 for 2 years"
     * 
     * Hardware: Phone Support + 999 cases (unlimited)
     * Software: Web Support + 100 cases (limited)
     */
    private static void createContractLineItemsAndEntitlements(List<Asset> assets, List<ServiceContract> contracts, Map<Id, List<OpportunityLineItem>> oppLineItemsMap) {
        List<ContractLineItem> cliList = new List<ContractLineItem>();
        List<Entitlement> entitlementList = new List<Entitlement>();
        
        // Group by account
        Map<Id, List<Asset>> assetsByAccount = new Map<Id, List<Asset>>();
        for (Asset asset : assets) {
            if (!assetsByAccount.containsKey(asset.AccountId)) {
                assetsByAccount.put(asset.AccountId, new List<Asset>());
            }
            assetsByAccount.get(asset.AccountId).add(asset);
        }
        
        // Create contract line items and entitlements
        for (ServiceContract contract : contracts) {
            if (assetsByAccount.containsKey(contract.AccountId)) {
                for (Asset asset : assetsByAccount.get(contract.AccountId)) {
                    // Match contract type with asset type
                    Boolean isMatch = false;
                    if (contract.Name.contains('Hardware') && asset.SerialNumber.startsWith('HW-')) {
                        isMatch = true;
                    } else if (contract.Name.contains('Software') && asset.SerialNumber.startsWith('PRD-')) {
                        isMatch = true;
                    }
                    
                    if (isMatch) {
                        // Find matching OpportunityLineItem for PricebookEntryId
                        Id pricebookEntryId = null;
                        for (List<OpportunityLineItem> oliList : oppLineItemsMap.values()) {
                            for (OpportunityLineItem oli : oliList) {
                                if (oli.Product2Id == asset.Product2Id) {
                                    pricebookEntryId = oli.PricebookEntryId;
                                    break;
                                }
                            }
                            if (pricebookEntryId != null) break;
                        }
                        
                        // Create Contract Line Item
                        ContractLineItem cli = new ContractLineItem(
                            ServiceContractId = contract.Id,
                            AssetId = asset.Id,
                            StartDate = contract.StartDate,
                            EndDate = contract.EndDate,
                            Discount = 0,
                            Quantity = asset.Quantity != null ? Integer.valueOf(asset.Quantity) : 1,
                            UnitPrice = 0,
                            PricebookEntryId = pricebookEntryId
                        );
                        cliList.add(cli);
                        
                        // Create Entitlement
                        Entitlement entitlement = createEntitlementForAsset(asset, contract);
                        if (entitlement != null) {
                            entitlementList.add(entitlement);
                        }
                    }
                }
            }
        }
        
        if (!cliList.isEmpty()) {
            insert cliList;
        }
        
        if (!entitlementList.isEmpty()) {
            insert entitlementList;
        }
    }
    
    /**
     * ENTITLEMENT CREATION
     * Creates customer's support membership with specific rights
     * 
     * Hardware Products: Premium Phone Support
     * Software Products: Standard Web Support
     * 
     * Note: CasesPerEntitlement removed due to Per Incident setting
     */
    private static Entitlement createEntitlementForAsset(Asset asset, ServiceContract contract) {
        String supportType = 'Web Support';
        
        // Hardware gets premium support
        if (asset.SerialNumber.startsWith('HW-')) {
            supportType = 'Phone Support';
        }
        
        return new Entitlement(
            Name = asset.Name + ' - Support Entitlement',
            AccountId = asset.AccountId,
            AssetId = asset.Id,
            ServiceContractId = contract.Id,
            StartDate = contract.StartDate,
            EndDate = contract.EndDate,
            Type = supportType
        );
    }
}