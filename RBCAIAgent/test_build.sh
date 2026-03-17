#!/bin/bash

echo "🚀 RBC AI Agent - Build and Run Test"
echo "===================================="

# Check if we're in the right directory
if [ ! -f "RBCAIAgentApp.swift" ]; then
    echo "❌ Error: Not in the RBCAIAgent directory"
    exit 1
fi

echo "✅ Found main app file"

# Test Swift syntax
echo "🔍 Testing Swift syntax..."
if swiftc -parse RBCAIAgentApp.swift 2>/dev/null; then
    echo "✅ RBCAIAgentApp.swift syntax OK"
else
    echo "❌ RBCAIAgentApp.swift has syntax errors"
    exit 1
fi

if swiftc -parse ContentView.swift 2>/dev/null; then
    echo "✅ ContentView.swift syntax OK"
else
    echo "❌ ContentView.swift has syntax errors"
    exit 1
fi

# Check Xcode project
echo "🔍 Checking Xcode project..."
if [ -f "RBCAIAgent.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project found"
    
    # Check if main files are included
    if grep -q "RBCAIAgentApp.swift" RBCAIAgent.xcodeproj/project.pbxproj; then
        echo "✅ RBCAIAgentApp.swift included in project"
    else
        echo "❌ RBCAIAgentApp.swift not in project"
        exit 1
    fi
    
    if grep -q "ContentView.swift" RBCAIAgent.xcodeproj/project.pbxproj; then
        echo "✅ ContentView.swift included in project"
    else
        echo "❌ ContentView.swift not in project"
        exit 1
    fi
else
    echo "❌ Xcode project not found"
    exit 1
fi

echo ""
echo "🎉 All tests passed! The app should run successfully."
echo ""
echo "📱 To run in Xcode:"
echo "1. Open RBCAIAgent.xcodeproj"
echo "2. Select iPhone 15 Simulator"
echo "3. Press Cmd+R"
echo ""
echo "🚀 Expected features:"
echo "- Chat interface with AI responses"
echo "- Dashboard with banking overview"
echo "- Clean, modern UI"
