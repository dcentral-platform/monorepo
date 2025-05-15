#!/usr/bin/env python3
"""
tree_assert.py - Validates directory structure against expected manifest

This script compares the actual directory structure with the expected structure
defined in a JSON manifest. It reports any missing or unexpected directories.

Usage:
  python tree_assert.py [--manifest MANIFEST]

Options:
  --manifest MANIFEST  Path to JSON manifest file (default: directory_manifest.json)
"""

import os
import sys
import json
import argparse
from pathlib import Path


def build_directory_tree(base_dir='.'):
    """
    Builds a set of directory paths starting from base_dir.
    Excludes hidden directories (starting with '.').
    """
    tree = set()
    base = Path(base_dir).resolve()
    
    for root, dirs, _ in os.walk(base):
        # Skip hidden directories
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        
        rel_path = Path(root).relative_to(base)
        if str(rel_path) != '.':  # Skip the root directory itself
            tree.add(str(rel_path))
    
    return tree


def load_expected_manifest(manifest_path):
    """
    Loads the expected directory structure from a JSON manifest file.
    Returns a set of expected directory paths.
    """
    try:
        with open(manifest_path, 'r') as f:
            manifest = json.load(f)
            
        expected_dirs = set(manifest.get('directories', []))
        return expected_dirs
    except Exception as e:
        print(f"Error loading manifest: {e}")
        sys.exit(1)


def compare_trees(actual, expected):
    """
    Compares actual and expected directory trees.
    Returns missing and unexpected directories.
    """
    missing = expected - actual
    unexpected = actual - expected
    
    return missing, unexpected


def create_default_manifest(base_dir='.', output_path='directory_manifest.json'):
    """
    Creates a default manifest based on the current directory structure.
    Useful for initializing a new project.
    """
    tree = build_directory_tree(base_dir)
    manifest = {
        'directories': sorted(list(tree))
    }
    
    with open(output_path, 'w') as f:
        json.dump(manifest, f, indent=2)
        
    print(f"Created default manifest at: {output_path}")


def main():
    parser = argparse.ArgumentParser(description='Validate directory structure against expected manifest')
    parser.add_argument('--manifest', default='directory_manifest.json', 
                        help='Path to JSON manifest file (default: directory_manifest.json)')
    parser.add_argument('--create-manifest', action='store_true',
                        help='Create a new manifest based on current directory structure')
    parser.add_argument('--base-dir', default='.',
                        help='Base directory to start from (default: current directory)')
    
    args = parser.parse_args()
    
    if args.create_manifest:
        create_default_manifest(args.base_dir, args.manifest)
        return 0
    
    # Validate directory structure
    actual_tree = build_directory_tree(args.base_dir)
    expected_tree = load_expected_manifest(args.manifest)
    
    missing, unexpected = compare_trees(actual_tree, expected_tree)
    
    if missing:
        print("Missing directories:")
        for d in sorted(missing):
            print(f"  - {d}")
    
    if unexpected:
        print("Unexpected directories:")
        for d in sorted(unexpected):
            print(f"  - {d}")
    
    # Create summary output
    total_missing = len(missing)
    total_unexpected = len(unexpected)
    
    print(f"\nSummary: {total_missing} missing, {total_unexpected} unexpected")
    
    if total_missing == 0 and total_unexpected == 0:
        print("✅ Directory structure matches expected manifest!")
        return 0
    else:
        print("❌ Directory structure does not match expected manifest.")
        return 1


if __name__ == "__main__":
    sys.exit(main())