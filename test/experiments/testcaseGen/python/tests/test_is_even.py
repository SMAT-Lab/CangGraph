import unittest

# The function to be tested
def is_even(n):
    return n % 2 == 0

# Test case for the is_even function
class TestIsEven(unittest.TestCase):

    def test_even_number(self):
        # Test if the function correctly identifies an even number
        self.assertTrue(is_even(4), "4 should be identified as even")

    def test_odd_number(self):
        # Test if the function correctly identifies an odd number
        self.assertFalse(is_even(7), "7 should be identified as odd")

    def test_zero(self):
        # Test if the function correctly identifies zero as even
        self.assertTrue(is_even(0), "0 should be identified as even")

# Run the tests
if __name__ == '__main__':
    unittest.main()