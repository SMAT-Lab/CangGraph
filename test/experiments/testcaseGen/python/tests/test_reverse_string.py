import unittest

# The function to be tested
def reverse_string(s):
    return s[::-1]

# Test case for the reverse_string function
class TestReverseString(unittest.TestCase):

    def test_reverse_normal_string(self):
        # Test reversing a normal string
        self.assertEqual(reverse_string("hello"), "olleh")
        self.assertEqual(reverse_string("python"), "nohtyp")

    def test_reverse_empty_string(self):
        # Test reversing an empty string
        self.assertEqual(reverse_string(""), "")

    def test_reverse_string_with_spaces(self):
        # Test reversing a string with spaces
        self.assertEqual(reverse_string("hello world"), "dlrow olleh")
        self.assertEqual(reverse_string("  spaces  "), "  secaps  ")

    def test_reverse_string_with_special_characters(self):
        # Test reversing a string with special characters
        self.assertEqual(reverse_string("!@#$%^&*"), "*&^%$#@!")
        self.assertEqual(reverse_string("123_abc"), "cba_321")

# Run the tests
if __name__ == '__main__':
    unittest.main()
