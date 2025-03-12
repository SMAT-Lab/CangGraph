import unittest

# The function to be tested
def concatenate_strings(*args):
    return ''.join(args)

# Test case for the concatenate_strings function
class TestConcatenateStrings(unittest.TestCase):

    def test_concatenate_two_strings(self):
        result = concatenate_strings("Hello, ", "World!")
        self.assertEqual(result, "Hello, World!")

    def test_concatenate_multiple_strings(self):
        result = concatenate_strings("Python", " ", "is", " ", "awesome!")
        self.assertEqual(result, "Python is awesome!")

    def test_concatenate_empty_strings(self):
        result = concatenate_strings("", "", "")
        self.assertEqual(result, "")

    def test_concatenate_no_arguments(self):
        result = concatenate_strings()
        self.assertEqual(result, "")

if __name__ == '__main__':
    unittest.main()
