import unittest

# The function to be tested
def max_of_three(a, b, c):
    return max(a, b, c)

# Test case for the max_of_three function
class TestMaxOfThree(unittest.TestCase):

    def test_all_positive_numbers(self):
        # Test with all positive numbers
        self.assertEqual(max_of_three(10, 20, 30), 30)
        self.assertEqual(max_of_three(5, 15, 10), 15)
        self.assertEqual(max_of_three(100, 200, 150), 200)

    def test_mixed_numbers(self):
        # Test with a mix of positive, negative, and zero
        self.assertEqual(max_of_three(-5, 0, 5), 5)
        self.assertEqual(max_of_three(-10, -20, 0), 0)
        self.assertEqual(max_of_three(-1, -2, -3), -1)

    def test_all_negative_numbers(self):
        # Test with all negative numbers
        self.assertEqual(max_of_three(-10, -20, -30), -10)
        self.assertEqual(max_of_three(-5, -15, -10), -5)
        self.assertEqual(max_of_three(-100, -200, -150), -100)

    def test_equal_numbers(self):
        # Test with all numbers being equal
        self.assertEqual(max_of_three(7, 7, 7), 7)
        self.assertEqual(max_of_three(-3, -3, -3), -3)
        self.assertEqual(max_of_three(0, 0, 0), 0)

# Run the tests
if __name__ == '__main__':
    unittest.main()
