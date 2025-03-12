import unittest

def multiply(a, b):
    return a * b

class TestMultiplyFunction(unittest.TestCase):
    def test_multiply_integers(self):
        # Test case for multiplying two positive integers
        self.assertEqual(multiply(3, 4), 12)

    def test_multiply_negative_numbers(self):
        # Test case for multiplying a positive and a negative integer
        self.assertEqual(multiply(-3, 4), -12)

    def test_multiply_zero(self):
        # Test case for multiplying by zero
        self.assertEqual(multiply(5, 0), 0)

    def test_multiply_floats(self):
        # Test case for multiplying two floating-point numbers
        self.assertEqual(multiply(2.5, 3.5), 8.75)

    def test_multiply_strings(self):
        # Test case for multiplying two strings (potential defect)
        self.assertEqual(multiply("a", 3), "aaa")

    def test_multiply_mixed_types(self):
        # Test case for multiplying a string and an integer (potential defect)
        self.assertEqual(multiply("a", 3), "aaa")

    def test_multiply_large_numbers(self):
        # Test case for multiplying large integers (potential overflow issue)
        self.assertEqual(multiply(10**18, 10**18), 10**36)

    def test_multiply_none(self):
        # Test case for multiplying with None (potential defect)
        with self.assertRaises(TypeError):
            multiply(None, 5)

if __name__ == '__main__':
    unittest.main()