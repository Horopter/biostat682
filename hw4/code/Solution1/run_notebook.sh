#!/bin/bash
# Script to run crime_bnn_optimized_parallel.ipynb in background with in-place execution

cd "/Users/santoshdesai/Desktop/si618fa2025/biostat682/hw4/Horopter Code/Solution1"

# Kill any existing nbconvert processes for this notebook
echo "Killing previous notebook executions..."
pkill -f "nbconvert.*Solution1.*sol1" 2>/dev/null || true
pkill -f "nbconvert.*sol1.ipynb" 2>/dev/null || true
sleep 1

# Run notebook in background with in-place execution
echo "Starting notebook execution in background..."
nohup jupyter nbconvert --execute --inplace --to notebook sol1.ipynb > sol1_exec.log 2>&1 &

# Get the process ID
PID=$!
echo "Notebook execution started with PID: $PID"
echo "Logs are being written to: sol1_exec.log"
echo "To check status: tail -f sol1_exec.log"
echo "To kill: kill $PID"

