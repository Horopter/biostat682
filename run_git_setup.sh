#!/bin/bash
# Git and GitHub Setup Script for BIOSTAT 682
# Run this script directly in your terminal: bash run_git_setup.sh

set -e  # Exit on error

cd /Users/santoshdesai/Desktop/si618fa2025/biostat682

echo "=========================================="
echo "Git and GitHub Setup"
echo "=========================================="
echo ""

# Step 1: Initialize git
echo "Step 1: Initializing git repository..."
if [ -d .git ]; then
    echo "  Git already initialized"
else
    git init
    echo "  ✓ Git initialized"
fi
echo ""

# Step 2: Configure git user
echo "Step 2: Configuring git user..."
git config user.name "Horopter"
git config user.email "santoshdesai12@hotmail.com"
echo "  ✓ User: Horopter"
echo "  ✓ Email: santoshdesai12@hotmail.com"
echo ""

# Step 3: Add files
echo "Step 3: Adding files to staging..."
git add .
STAGED_COUNT=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo "  ✓ $STAGED_COUNT files staged"
echo ""

# Step 4: Create commit
echo "Step 4: Creating initial commit..."
if git diff --cached --quiet; then
    echo "  No changes to commit (already committed)"
else
    git commit -m "Initial commit: BIOSTAT 682 Fall 2025 Coursework

- HW1: Introduction to Bayesian methods
- HW2: Bayesian inference exercises  
- HW3: Bayesian regression models
- HW4: Bayesian Neural Networks and classification
- Lecture notes and code exports"
    echo "  ✓ Commit created"
fi
echo ""

# Step 5: Set branch to main
echo "Step 5: Setting branch to main..."
git branch -M main
CURRENT_BRANCH=$(git branch --show-current)
echo "  ✓ Current branch: $CURRENT_BRANCH"
echo ""

# Step 6: Create GitHub repository
echo "Step 6: Creating GitHub repository..."
if command -v gh &> /dev/null; then
    echo "  GitHub CLI found, attempting to create repository..."
    if gh repo create biostat682 --public --source=. --remote=origin --push 2>&1; then
        echo ""
        echo "=========================================="
        echo "✅ SUCCESS! Repository created and pushed!"
        echo "=========================================="
        echo "Repository URL: https://github.com/Horopter/biostat682"
    else
        echo "  ⚠️  GitHub CLI command failed"
        echo "  Adding remote manually..."
        git remote remove origin 2>/dev/null || true
        git remote add origin https://github.com/Horopter/biostat682.git
        echo "  ✓ Remote added"
        echo ""
        echo "  Please create the repository manually:"
        echo "  1. Go to: https://github.com/new"
        echo "  2. Repository name: biostat682"
        echo "  3. Make it public"
        echo "  4. DO NOT initialize with README"
        echo "  5. Then run: git push -u origin main"
    fi
else
    echo "  GitHub CLI not found"
    echo "  Adding remote..."
    git remote remove origin 2>/dev/null || true
    git remote add origin https://github.com/Horopter/biostat682.git
    echo "  ✓ Remote added"
    echo ""
    echo "  Next steps:"
    echo "  1. Create repository at: https://github.com/new"
    echo "     Repository name: biostat682"
    echo "  2. Then run: git push -u origin main"
fi

echo ""
echo "=========================================="
echo "Final Status"
echo "=========================================="
echo ""
echo "Git status:"
git status --short | head -10
echo ""
echo "Recent commits:"
git log --oneline -3
echo ""
echo "Remote configuration:"
git remote -v
echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="

