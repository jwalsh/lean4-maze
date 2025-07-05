import leanclient as lc
import os
import sys

def main():
    """
    A simple test script for reading Maze.lean without requiring Lake build
    """
    print("Simple Lean Client Test")
    print("-----------------------")
    
    # Get the current directory
    project_path = os.getcwd()
    print(f"Project path: {project_path}")
    
    # Check if Maze.lean exists
    file_path = os.path.join(project_path, "Maze.lean")
    if not os.path.exists(file_path):
        print(f"Error: {file_path} not found")
        return 1
    
    print(f"Found Maze.lean file: {file_path}")
    
    # Instead of using the LeanLSPClient which requires lake build,
    # we'll just read the file directly
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Print the first 10 lines
        lines = content.split('\n')
        print("\nFile content (first 10 lines):")
        for i, line in enumerate(lines[:10]):
            print(f"{i+1}: {line}")
        
        # Print information about the file
        print(f"\nTotal lines: {len(lines)}")
        print(f"File size: {os.path.getsize(file_path)} bytes")
        
        # Look for certain patterns in the file
        structures = [line for line in lines if line.strip().startswith('structure ')]
        if structures:
            print("\nStructures defined in the file:")
            for struct in structures:
                print(f"  - {struct.strip()}")
        
        syntax = [line for line in lines if line.strip().startswith('declare_syntax')]
        if syntax:
            print("\nSyntax declarations in the file:")
            for syn in syntax:
                print(f"  - {syn.strip()}")
        
        return 0
    except Exception as e:
        print(f"Error reading file: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())