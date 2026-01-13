
def count_braces(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    open_braces = 0
    close_braces = 0
    stack = []
    
    for i, char in enumerate(content):
        if char == '{':
            open_braces += 1
            stack.append(i)
        elif char == '}':
            close_braces += 1
            if stack:
                stack.pop()
    
    print(f"File: {file_path}")
    print(f"Open: {open_braces}, Close: {close_braces}")
    if open_braces != close_braces:
        print(f"Mismatch! Difference: {open_braces - close_braces}")
        if stack:
            print(f"Last unmatched open brace at char index: {stack[-1]}")
    else:
        print("Braces match.")

if __name__ == "__main__":
    count_braces("/home/adminlotfy/project/lib/presentation/widgets/details/dosage_tab.dart")
