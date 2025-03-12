import unittest

# The function to be tested
def sum_of_list(lst):
    return sum(lst)

# Test case for the sum_of_list function
class TestSumOfList(unittest.TestCase):

    def test_sum_of_positive_numbers(self):
        # Test with a list of positive numbers
        self.assertEqual(sum_of_list([1, 2, 3, 4, 5]), 15)

    def test_sum_of_negative_numbers(self):
        # Test with a list of negative numbers
        self.assertEqual(sum_of_list([-1, -2, -3, -4, -5]), -15)

    def test_sum_of_mixed_numbers(self):
        # Test with a list of mixed positive and negative numbers
        self.assertEqual(sum_of_list([-1, 2, -3, 4, -5]), -3)

    def test_sum_of_empty_list(self):
        # Test with an empty list
        self.assertEqual(sum_of_list([]), 0)

    def test_sum_of_single_element(self):
        # Test with a list containing a single element
        self.assertEqual(sum_of_list([42]), 42)

# Run the tests
if __name__ == '__main__':
    unittest.main()