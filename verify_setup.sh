#!/bin/bash
cd /Users/santoshdesai/Desktop/si618fa2025/biostat682

echo "=== Git Setup Verification ===" > setup_verification.txt
echo "" >> setup_verification.txt

if [ -d .git ]; then
    echo "✓ Git initialized" >> setup_verification.txt
    echo "✓ Git initialized"
else
    echo "✗ Git not initialized" >> setup_verification.txt
    echo "✗ Git not initialized"
fi

echo "" >> setup_verification.txt
echo "User Configuration:" >> setup_verification.txt
git config user.name >> setup_verification.txt 2>&1
git config user.email >> setup_verification.txt 2>&1

echo "" >> setup_verification.txt
echo "Recent Commits:" >> setup_verification.txt
git log --oneline -3 >> setup_verification.txt 2>&1

echo "" >> setup_verification.txt
echo "Current Branch:" >> setup_verification.txt
git branch --show-current >> setup_verification.txt 2>&1

echo "" >> setup_verification.txt
echo "Remote Configuration:" >> setup_verification.txt
git remote -v >> setup_verification.txt 2>&1

echo "" >> setup_verification.txt
echo "Git Status:" >> setup_verification.txt
git status --short >> setup_verification.txt 2>&1

cat setup_verification.txt

