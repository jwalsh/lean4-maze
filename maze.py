import leanclient as lc

# Start a new client, point it to the project root (where lakefile.lean is located).
PROJECT_PATH = "."
client = lc.LeanLSPClient(PROJECT_PATH)

# Query the Maze.lean file in the project
file_path = "Maze.lean"
result = client.get_goal(file_path, line=10, character=2)
print("Goal at line 10, character 2:")
print(result)

# Use a SingleFileClient for simplified interaction with a single file.
sfc = client.create_file_client(file_path)
result = sfc.get_term_goal(line=5, character=5)
print("\nTerm goal at line 5, character 5:")
print(result)

# Make a change to the document.
change = lc.DocumentContentChange(text="-- Modified by leanclient\n", start=[1, 0], end=[1, 0])
sfc.update_file(changes=[change])

# Check the document content as seen by the LSP (changes are not written to disk).
print("\nModified file content (not written to disk):")
print(sfc.get_file_content().split("\n")[:5])  # Show first 5 lines only

# Get diagnostics for the file
diagnostics = sfc.get_diagnostics()
print("\nDiagnostics:")
print(diagnostics)