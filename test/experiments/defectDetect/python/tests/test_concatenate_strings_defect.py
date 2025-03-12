import unittest

def concatenate_strings(*args):
    return ''.join(args)

class TestConcatenateStrings(unittest.TestCase):
    def test_concatenate_strings(self):
        # Test case 1: Normal input
        result = concatenate_strings("hello", " ", "world")
        self.assertEqual(result, "hello world")

        # Test case 2: Empty strings
        result = concatenate_strings("", "", "")
        self.assertEqual(result, "")

        # Test case 3: Single string
        result = concatenate_strings("single")
        self.assertEqual(result, "single")

        # Test case 4: Non-string input (potential defect)
        # result = concatenate_strings(1, 2, 3)
        # This will raise a TypeError because join() expects strings

        # Test case 5: Mixed types (potential defect)
        # result = concatenate_strings("hello", 123, "world")
        # This will raise a TypeError because join() expects strings

        # Test case 6: No arguments (potential defect)
        result = concatenate_strings()
        self.assertEqual(result, "")

if __name__ == "__main__":
    unittest.main()