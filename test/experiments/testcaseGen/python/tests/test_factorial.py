import unittest

# The function to be tested
def factorial(n):
    return 1 if n == 0 else n * factorial(n - 1)

# Test case for the factorial function
class TestFactorial(unittest.TestCase):

    def test_factorial_of_zero(self):
        # Test that the factorial of 0 is 1
        self.assertEqual(factorial(0), 1)

    def test_factorial_of_positive_integer(self):
        # Test the factorial of a positive integer
        self.assertEqual(factorial(1), 1)
        self.assertEqual(factorial(5), 120)
        self.assertEqual(factorial(7), 5040)

    def test_factorial_of_negative_integer(self):
        # Test that the factorial of a negative integer raises a ValueError
        with self.assertRaises(ValueError):
            factorial(-1)
        with self.assertRaises(ValueError):
            factorial(-5)

if __name__ == '__main__':
    unittest.main()
