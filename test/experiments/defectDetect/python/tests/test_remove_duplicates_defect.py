import unittest

def remove_duplicates(lst):
    return list(set(lst))

class TestRemoveDuplicates(unittest.TestCase):
    def test_empty_list(self):
        # Potential defect: The function should handle empty lists.
        result = remove_duplicates([])
        self.assertEqual(result, [])

    def test_no_duplicates(self):
        # Potential defect: The function should preserve the order of elements.
        result = remove_duplicates([1, 2, 3])
        self.assertEqual(result, [1, 2, 3])

    def test_with_duplicates(self):
        # Potential defect: The function does not preserve the order of elements.
        result = remove_duplicates([1, 2, 2, 3, 1])
        self.assertEqual(result, [1, 2, 3])

    def test_mixed_types(self):
        # Potential defect: The function may not handle mixed types correctly.
        result = remove_duplicates([1, '1', 2, '2'])
        self.assertEqual(result, [1, '1', 2, '2'])

    # def test_nested_lists(self):
    #     # Potential defect: The function does not handle nested lists.
    #     result = remove_duplicates([[1, 2], [2, 3], [1, 2]])
    #     self.assertEqual(result, [[1, 2], [2, 3]])

    def test_unhashable_types(self):
        # Potential defect: The function does not handle unhashable types like lists.
        with self.assertRaises(TypeError):
            remove_duplicates([[1, 2], [3, 4], [1, 2]])

if __name__ == '__main__':
    unittest.main()