#!/bin/bash
set -e

cd /Users/santoshdesai/Desktop/si618fa2025/biostat682

echo "=========================================="
echo "Setting up Git and GitHub repository"
echo "=========================================="
echo ""

# Step 1: Initialize git
echo "Step 1: Initializing git repository..."
git init
echo "✓ Git initialized"
echo ""

# Step 2: Configure git
echo "Step 2: Configuring git user..."
git config user.name "Horopter"
git config user.email "santoshdesai12@hotmail.com"
echo "✓ User configured: Horopter <santoshdesai12@hotmail.com>"
echo ""

# Step 3: Add files
echo "Step 3: Adding files to staging..."
git add .
echo "✓ Files added"
echo ""

# Step 4: Create commit
echo "Step 4: Creating initial commit..."
git commit -m "Initial commit: BIOSTAT 682 Fall 2025 Coursework"
echo "✓ Commit created"
echo ""

# Step 5: Set branch
echo "Step 5: Setting branch to main..."
git branch -M main
echo "✓ Branch set to main"
echo ""

# Step 6: Create GitHub repo
echo "Step 6: Creating GitHub repository..."
if gh repo create biostat682 --public --source=. --remote=origin --push 2>&1; then
    echo ""
    echo "=========================================="
    echo "✅ SUCCESS! Repository created and pushed!"
    echo "=========================================="
    echo "Repository URL: https://github.com/Horopter/biostat682"
else
    echo ""
    echo "⚠️  GitHub CLI command failed. Adding remote manually..."
    git remote add origin https://github.com/Horopter/biostat682.git 2>&1 || true
    echo "✓ Remote added"
    echo ""
    echo "Next steps:"
    echo "1. Create repository at: https://github.com/new"
    echo "   Repository name: biostat682"
    echo "2. Then run: git push -u origin main"
fi

echo ""
echo "=========================================="
echo "Final Status:"
echo "=========================================="
git status --short | head -10
echo ""
echo "Recent commits:"
git log --oneline -3
echo ""
echo "Remote configuration:"
git remote -v
echo "=========================================="

