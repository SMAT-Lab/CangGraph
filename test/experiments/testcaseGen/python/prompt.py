import requests
import json

API_URL = "https://api.deepseek.com/v1/chat/completions"
API_KEY = "sk-8dd8324c6ad344eea0be1316bdf720c4"
MODEL = "deepseek-chat"
SYSTEM_PROMPT = "You are a helpful assistant that generates Python test cases for given functions."


functions_to_test = [
    "def add(a, b): return a + b",
    "def multiply(a, b): return a * b",
    "def is_even(n): return n % 2 == 0",
    "def reverse_string(s): return s[::-1]",
    "def factorial(n): return 1 if n == 0 else n * factorial(n - 1)",
    "def max_of_three(a, b, c): return max(a, b, c)",
    "def sum_of_list(lst): return sum(lst)",
    "def is_prime(n): return n > 1 and all(n % i != 0 for i in range(2, int(n**0.5) + 1))",
    "def concatenate_strings(*args): return ''.join(args)",
    "def remove_duplicates(lst): return list(set(lst))"
]

def generate_test_cases(functions):
    test_cases = []
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    for func in functions:
        prompt = (
            f"Generate a complete Python test case for the following function using the unittest framework:\n"
            f"{func}\n"
            "Ensure the test case includes at least three test methods covering different scenarios."
        )
        data = {
            "model": MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.5,
            "max_tokens": 500
        }

        response = requests.post(API_URL, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        result = response.json()

        test_case = result["choices"][0]["message"]["content"].strip()
        test_cases.append(test_case)
        print(f"Generated test case for function:\n{func}\nTest Case:\n{test_case}\n")

    return test_cases

if __name__ == "__main__":
    output_file = "test_cases_output.txt"
    with open(output_file, "w") as f:
        f.write("Generated Test Cases:\n")
        test_cases = generate_test_cases(functions_to_test)
        for i, test_case in enumerate(test_cases, start=1):
            f.write(f"Test Case {i}:\n{test_case}\n\n")
            print(f"Test Case {i}:\n{test_case}\n")

    print(f"All generated test cases have been saved to {output_file}")