#!/usr/bin/env python3
"""
Check code coverage thresholds for claude-code.nvim
- Fail if any file is below 25% coverage
- Fail if overall coverage is below 70%
"""

import sys
import re
from pathlib import Path

def parse_luacov_report(report_file):
    """Parse luacov report and extract coverage data."""
    if not Path(report_file).exists():
        print(f"Error: Coverage report '{report_file}' not found")
        return None
    
    with open(report_file, 'r') as f:
        content = f.read()
    
    # Parse individual file coverage
    file_coverage = {}
    
    # Pattern to match file coverage lines
    # Example: lua/claude-code/init.lua                   100.00%   123     0
    file_pattern = r'^(lua/claude-code/[^\s]+\.lua)\s+(\d+\.\d+)%\s+(\d+)\s+(\d+)'
    
    for line in content.split('\n'):
        match = re.match(file_pattern, line)
        if match:
            filename = match.group(1)
            coverage = float(match.group(2))
            hits = int(match.group(3))
            misses = int(match.group(4))
            file_coverage[filename] = {
                'coverage': coverage,
                'hits': hits,
                'misses': misses
            }
    
    # Parse summary line
    # Example: Total                      85.42%   410    58
    summary_pattern = r'^Total\s+(\d+\.\d+)%\s+(\d+)\s+(\d+)'
    total_coverage = None
    
    for line in content.split('\n'):
        match = re.match(summary_pattern, line)
        if match:
            total_coverage = float(match.group(1))
            break
    
    return {
        'files': file_coverage,
        'total': total_coverage
    }

def check_coverage_thresholds(coverage_data, file_threshold=25.0, total_threshold=70.0):
    """Check if coverage meets the thresholds."""
    if not coverage_data:
        return False, ["No coverage data available"]
    
    failures = []
    
    # Check individual file thresholds
    for filename, data in coverage_data['files'].items():
        if data['coverage'] < file_threshold:
            failures.append(
                f"File '{filename}' coverage {data['coverage']:.2f}% "
                f"is below threshold of {file_threshold}%"
            )
    
    # Check total coverage threshold
    if coverage_data['total'] is not None:
        if coverage_data['total'] < total_threshold:
            failures.append(
                f"Total coverage {coverage_data['total']:.2f}% "
                f"is below threshold of {total_threshold}%"
            )
    else:
        failures.append("Could not determine total coverage")
    
    return len(failures) == 0, failures

def main():
    """Main function."""
    report_file = "luacov.report.out"
    
    print("Checking code coverage thresholds...")
    print("=" * 60)
    
    # Parse coverage report
    coverage_data = parse_luacov_report(report_file)
    
    if not coverage_data:
        print("Error: Failed to parse coverage report")
        sys.exit(1)
    
    # Display coverage summary
    print(f"Total Coverage: {coverage_data['total']:.2f}%")
    print(f"Files Analyzed: {len(coverage_data['files'])}")
    print()
    
    # Check thresholds
    passed, failures = check_coverage_thresholds(coverage_data)
    
    if passed:
        print("✅ All coverage thresholds passed!")
        
        # Show file coverage
        print("\nFile Coverage Summary:")
        print("-" * 60)
        for filename, data in sorted(coverage_data['files'].items()):
            status = "✅" if data['coverage'] >= 25 else "❌"
            print(f"{status} {filename:<45} {data['coverage']:>6.2f}%")
    else:
        print("❌ Coverage thresholds failed!")
        print("\nFailures:")
        for failure in failures:
            print(f"  - {failure}")
        
        # Show file coverage
        print("\nFile Coverage Summary:")
        print("-" * 60)
        for filename, data in sorted(coverage_data['files'].items()):
            status = "✅" if data['coverage'] >= 25 else "❌"
            print(f"{status} {filename:<45} {data['coverage']:>6.2f}%")
        
        sys.exit(1)

if __name__ == "__main__":
    main()