import unittest

# The function to be tested
def is_prime(n):
    return n > 1 and all(n % i != 0 for i in range(2, int(n**0.5) + 1))

# Test case for the is_prime function
class TestIsPrime(unittest.TestCase):

    def test_prime_numbers(self):
        # Test for prime numbers
        self.assertTrue(is_prime(2), "2 should be a prime number")
        self.assertTrue(is_prime(3), "3 should be a prime number")
        self.assertTrue(is_prime(5), "5 should be a prime number")
        self.assertTrue(is_prime(7), "7 should be a prime number")
        self.assertTrue(is_prime(11), "11 should be a prime number")
        self.assertTrue(is_prime(13), "13 should be a prime number")

    def test_non_prime_numbers(self):
        # Test for non-prime numbers
        self.assertFalse(is_prime(1), "1 should not be a prime number")
        self.assertFalse(is_prime(4), "4 should not be a prime number")
        self.assertFalse(is_prime(6), "6 should not be a prime number")
        self.assertFalse(is_prime(8), "8 should not be a prime number")
        self.assertFalse(is_prime(9), "9 should not be a prime number")
        self.assertFalse(is_prime(10), "10 should not be a prime number")

    def test_edge_cases(self):
        # Test edge cases
        self.assertFalse(is_prime(0), "0 should not be a prime number")
        self.assertFalse(is_prime(-1), "-1 should not be a prime number")
        self.assertFalse(is_prime(-7), "-7 should not be a prime number")
        self.assertTrue(is_prime(29), "29 should be a prime number")
        self.assertFalse(is_prime(30), "30 should not be a prime number")

# Run the tests
if __name__ == '__main__':
    unittest.main()
