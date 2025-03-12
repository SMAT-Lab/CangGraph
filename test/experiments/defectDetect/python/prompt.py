import requests
import json

API_URL = "https://api.deepseek.com/v1/chat/completions"
API_KEY = "sk-8dd8324c6ad344eea0be1316bdf720c4"
MODEL = "deepseek-chat"
SYSTEM_PROMPT = "You are a helpful assistant that generates Python code defect detection examples."

code_samples = [
    "def add(a, b):\n    return a + b",
    "def multiply(a, b):\n    return a * b",
    "def is_even(n):\n    return n % 2 == 0",
    "def reverse_string(s):\n    return s[::-1]",
    "def factorial(n):\n    return 1 if n == 0 else n * factorial(n - 1)",
    "def max_of_three(a, b, c):\n    return max(a, b, c)",
    "def sum_of_list(lst):\n    return sum(lst)",
    "def is_prime(n):\n    return n > 1 and all(n % i != 0 for i in range(2, int(n**0.5) + 1))",
    "def concatenate_strings(*args):\n    return ''.join(args)",
    "def remove_duplicates(lst):\n    return list(set(lst))"
]

def generate_defect_detection_samples(codes):
    defect_detection_samples = []
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }

    for code in codes:
        prompt = (
            f"Generate a Python code defect detection example for the following function:\n{code}\n"
            "Identify potential defects or issues in the code directly and don't suggest any improvements."
            "Show the answer as a test file less than 500 tokens."
        )
        data = {
            "model": MODEL,
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": prompt}
            ],
            "temperature": 0.7,
            "max_tokens": 700
        }

        response = requests.post(API_URL, headers=headers, data=json.dumps(data))
        response.raise_for_status()
        result = response.json()

        defect_detection_sample = result["choices"][0]["message"]["content"].strip()
        defect_detection_samples.append(defect_detection_sample)
        print(f"Generated defect detection sample for code:\n{code}\nDefect Detection Sample:\n{defect_detection_sample}\n")

    return defect_detection_samples

if __name__ == "__main__":
    output_file = "defect_detection_samples.txt"
    with open(output_file, "w") as f:
        f.write("Generated Code Defect Detection Samples:\n")
        defect_detection_samples = generate_defect_detection_samples(code_samples)
        for i, sample in enumerate(defect_detection_samples, start=1):
            f.write(f"Sample {i}:\n{sample}\n\n")
            # print(f"Sample {i}:\n{sample}\n")

    print(f"All generated defect detection samples have been saved to {output_file}")