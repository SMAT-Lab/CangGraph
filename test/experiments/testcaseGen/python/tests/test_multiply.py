import unittest

# The function to be tested
def multiply(a, b):
    return a * b

# Test case for the multiply function
class TestMultiplyFunction(unittest.TestCase):

    def test_multiply_positive_numbers(self):
        # Test multiplying two positive numbers
        result = multiply(3, 4)
        self.assertEqual(result, 12, "Expected 3 * 4 to be 12")

    def test_multiply_negative_numbers(self):
        # Test multiplying two negative numbers
        result = multiply(-2, -5)
        self.assertEqual(result, 10, "Expected -2 * -5 to be 10")

    def test_multiply_with_zero(self):
        # Test multiplying a number with zero
        result = multiply(7, 0)
        self.assertEqual(result, 0, "Expected 7 * 0 to be 0")

    def test_multiply_positive_and_negative(self):
        # Test multiplying a positive number with a negative number
        result = multiply(6, -3)
        self.assertEqual(result, -18, "Expected 6 * -3 to be -18")

# Run the tests
if __name__ == '__main__':
    unittest.main()