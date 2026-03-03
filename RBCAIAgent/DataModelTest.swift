import Foundation
import SwiftUI

// MARK: - Data Model Test Suite

struct DataModelTest {
    
    // Test Account Model
    static func testAccountModel() -> Bool {
        print("🧪 Testing Account Model...")
        
        // Create test account
        let account = Account(
            id: "test-acc-1",
            accountNumber: "****1234",
            accountType: .chequing,
            balance: 1000.50,
            currency: "CAD",
            nickname: "Test Account",
            isActive: true,
            transactions: []
        )
        
        // Verify properties
        assert(account.id == "test-acc-1")
        assert(account.accountType == .chequing)
        assert(account.balance == 1000.50)
        assert(account.currency == "CAD")
        assert(account.nickname == "Test Account")
        assert(account.isActive == true)
        assert(account.transactions.isEmpty)
        
        print("✅ Account Model Test Passed")
        return true
    }
    
    // Test Transaction Model
    static func testTransactionModel() -> Bool {
        print("🧪 Testing Transaction Model...")
        
        let transaction = Transaction(
            id: "test-tx-1",
            date: Date(),
            description: "Test Transaction",
            amount: -50.25,
            category: .groceries,
            merchant: "Test Store",
            isPending: false,
            accountId: "test-acc-1"
        )
        
        assert(transaction.id == "test-tx-1")
        assert(transaction.amount == -50.25)
        assert(transaction.category == .groceries)
        assert(transaction.merchant == "Test Store")
        assert(!transaction.isPending)
        assert(transaction.accountId == "test-acc-1")
        
        print("✅ Transaction Model Test Passed")
        return true
    }
    
    // Test UserProfile Model
    static func testUserProfileModel() -> Bool {
        print("🧪 Testing UserProfile Model...")
        
        let userProfile = UserProfile(
            name: "Test User",
            email: "test@example.com",
            phoneNumber: "+1-555-0123",
            memberSince: Date(),
            preferredName: "Test",
            privacySettings: PrivacySettings()
        )
        
        assert(userProfile.name == "Test User")
        assert(userProfile.email == "test@example.com")
        assert(userProfile.preferredName == "Test")
        assert(!userProfile.privacySettings.shareTransactionData)
        
        print("✅ UserProfile Model Test Passed")
        return true
    }
    
    // Test AccountInsight Model
    static func testAccountInsightModel() -> Bool {
        print("🧪 Testing AccountInsight Model...")
        
        let insight = AccountInsight(
            id: "insight-1",
            type: .spendingPattern,
            title: "Test Insight",
            description: "This is a test insight",
            severity: .medium,
            date: Date(),
            relatedAccountIds: ["acc1", "acc2"],
            actionable: true
        )
        
        assert(insight.id == "insight-1")
        assert(insight.type == .spendingPattern)
        assert(insight.severity == .medium)
        assert(insight.actionable == true)
        assert(insight.relatedAccountIds.count == 2)
        
        print("✅ AccountInsight Model Test Passed")
        return true
    }
    
    // Test RBCDataManager
    static func testRBCDataManager() -> Bool {
        print("🧪 Testing RBCDataManager...")
        
        let dataManager = RBCDataManager()
        
        // Test initial state
        assert(!dataManager.accounts.isEmpty)
        assert(dataManager.userProfile.name == "Alex Johnson")
        assert(!dataManager.insights.isEmpty)
        
        // Test calculations
        let totalBalance = dataManager.getTotalBalance()
        let totalDebt = dataManager.getTotalDebt()
        let netWorth = dataManager.getNetWorth()
        
        assert(totalBalance >= 0)
        assert(totalDebt >= 0)
        assert(netWorth == totalBalance - totalDebt)
        
        // Test spending analysis
        let spendingByCategory = dataManager.getSpendingByCategory()
        let monthlyTrend = dataManager.getMonthlySpendingTrend()
        
        assert(!spendingByCategory.isEmpty)
        assert(monthlyTrend.count <= 6) // Should have up to 6 months
        
        print("✅ RBCDataManager Test Passed")
        return true
    }
    
    // Test ChatMessage Model
    static func testChatMessageModel() -> Bool {
        print("🧪 Testing ChatMessage Model...")
        
        let message = ChatMessage(
            id: "msg-1",
            content: "Hello, this is a test message",
            isFromUser: true,
            timestamp: Date()
        )
        
        assert(message.id == "msg-1")
        assert(message.content == "Hello, this is a test message")
        assert(message.isFromUser == true)
        
        print("✅ ChatMessage Model Test Passed")
        return true
    }
    
    // Test VoiceCallRecord Model
    static func testVoiceCallRecordModel() -> Bool {
        print("🧪 Testing VoiceCallRecord Model...")
        
        let callRecord = VoiceCallRecord(
            id: "call-1",
            startTime: Date().addingTimeInterval(-300), // 5 minutes ago
            endTime: Date(),
            duration: 300,
            transcription: "Test transcription",
            agentResponse: "Test response",
            callQuality: .excellent,
            wasSuccessful: true
        )
        
        assert(callRecord.id == "call-1")
        assert(callRecord.duration == 300)
        assert(callRecord.callQuality == .excellent)
        assert(callRecord.wasSuccessful == true)
        assert(!callRecord.transcription.isEmpty)
        
        print("✅ VoiceCallRecord Model Test Passed")
        return true
    }
    
    // Test MarketData Model
    static func testMarketDataModel() -> Bool {
        print("🧪 Testing MarketData Model...")
        
        let marketData = MarketData()
        let indexData = MarketIndexData(
            name: "S&P 500",
            value: 4500.0,
            change: 25.5,
            changePercent: 0.57,
            volume: 1000000,
            high: 4525.0,
            low: 4475.0,
            open: 4480.0,
            dividendYield: 1.5
        )
        
        assert(indexData.name == "S&P 500")
        assert(indexData.value == 4500.0)
        assert(indexData.change == 25.5)
        
        print("✅ MarketData Model Test Passed")
        return true
    }
    
    // Run all tests
    static func runAllTests() {
        print("🚀 Starting Data Model Test Suite...")
        print("=" * 50)
        
        var testsPassed = 0
        let totalTests = 8
        
        if testAccountModel() { testsPassed += 1 }
        if testTransactionModel() { testsPassed += 1 }
        if testUserProfileModel() { testsPassed += 1 }
        if testAccountInsightModel() { testsPassed += 1 }
        if testRBCDataManager() { testsPassed += 1 }
        if testChatMessageModel() { testsPassed += 1 }
        if testVoiceCallRecordModel() { testsPassed += 1 }
        if testMarketDataModel() { testsPassed += 1 }
        
        print("=" * 50)
        print("📊 Test Results: \(testsPassed)/\(totalTests) tests passed")
        
        if testsPassed == totalTests {
            print("🎉 ALL DATA MODEL TESTS PASSED!")
            print("✅ The RBC AI Agent data model is working correctly!")
        } else {
            print("❌ Some tests failed. Please check the implementation.")
        }
    }
}

// Extension for string repetition
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}
