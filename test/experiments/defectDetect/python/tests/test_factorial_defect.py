import unittest

def factorial(n):
    return 1 if n == 0 else n * factorial(n - 1)

class TestFactorial(unittest.TestCase):
    def test_factorial_of_zero(self):
        self.assertEqual(factorial(0), 1)

    def test_factorial_of_positive_number(self):
        self.assertEqual(factorial(5), 120)

    def test_factorial_of_negative_number(self):
        with self.assertRaises(RecursionError):
            factorial(-1)

    def test_factorial_of_large_number(self):
        with self.assertRaises(RecursionError):
            factorial(1000)

if __name__ == '__main__':
    unittest.main()