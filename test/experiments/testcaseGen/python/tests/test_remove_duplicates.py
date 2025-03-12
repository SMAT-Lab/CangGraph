import unittest

# The function to be tested
def remove_duplicates(lst):
    return list(set(lst))

# Test case for the remove_duplicates function
class TestRemoveDuplicates(unittest.TestCase):

    def test_no_duplicates(self):
        # Test case with no duplicates
        input_list = [1, 2, 3, 4, 5]
        expected_output = [1, 2, 3, 4, 5]
        result = remove_duplicates(input_list)
        self.assertCountEqual(result, expected_output)  # Order may vary, but elements should match

    def test_with_duplicates(self):
        # Test case with duplicates
        input_list = [1, 2, 2, 3, 4, 4, 5]
        expected_output = [1, 2, 3, 4, 5]
        result = remove_duplicates(input_list)
        self.assertCountEqual(result, expected_output)  # Order may vary, but elements should match

    def test_empty_list(self):
        # Test case with an empty list
        input_list = []
        expected_output = []
        result = remove_duplicates(input_list)
        self.assertEqual(result, expected_output)

    def test_all_duplicates(self):
        # Test case where all elements are duplicates
        input_list = [1, 1, 1, 1, 1]
        expected_output = [1]
        result = remove_duplicates(input_list)
        self.assertEqual(result, expected_output)

# Run the tests
if __name__ == '__main__':
    unittest.main()
