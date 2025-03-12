import unittest

# The function to be tested
def add(a, b):
    return a + b

# Test case for the add function
class TestAddFunction(unittest.TestCase):

    def test_add_positive_numbers(self):
        # Test adding two positive numbers
        result = add(3, 5)
        self.assertEqual(result, 8, "Expected 3 + 5 to be 8")

    def test_add_positive_and_negative(self):
        # Test adding a positive and a negative number
        result = add(10, -4)
        self.assertEqual(result, 6, "Expected 10 + (-4) to be 6")

    def test_add_negative_numbers(self):
        # Test adding two negative numbers
        result = add(-7, -3)
        self.assertEqual(result, -10, "Expected (-7) + (-3) to be -10")

    def test_add_zero(self):
        # Test adding zero to a number
        result = add(0, 5)
        self.assertEqual(result, 5, "Expected 0 + 5 to be 5")
        result = add(5, 0)
        self.assertEqual(result, 5, "Expected 5 + 0 to be 5")

# Run the tests
if __name__ == '__main__':
    unittest.main()