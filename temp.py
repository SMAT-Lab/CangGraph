def ADD(a1, a2):
    return a1 + a2

def minus(b1, b2):
    return b1 - b2

def calculator():
    print("Welcome to the Simple Calculator!")
    print("Select an operation:")
    print("1. Addition")
    print("2. Subtraction")

    choice = input("Enter choice (1/2): ")

    if choice in ['1', '2']:
        num1 = float(input("Enter first number: "))
        num2 = float(input("Enter second number: "))

        if choice == '1':
            result = ADD(num1, num2)
            print(f"The result of {num1} + {num2} = {result}")
        elif choice == '2':
            result = minus(num1, num2)
            print(f"The result of {num1} - {num2} = {result}")
    else:
        print("Invalid input. Please select either 1 or 2.")

if __name__ == "__main__":
    calculator()
'''
### Explanation:
1. **Function Definitions**: 
   - The `ADD` function takes two parameters and returns their sum.
   - The `minus` function takes two parameters and returns their difference.

2. **User Interaction**:
   - The `calculator` function prints a welcome message and asks for the operation choice (addition or subtraction).
   - Depending on the user's choice, it prompts for two numbers and performs the selected operation.
   - Finally, it prints the result.

3. **Execution**:
   - The `if __name__ == "__main__":` block ensures that the `calculator` function runs only when the script is executed directly.

You can run this code in a Python environment to see how the calculator works!
'''
